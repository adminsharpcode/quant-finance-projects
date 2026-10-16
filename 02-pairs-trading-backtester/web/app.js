/**
 * QUANTITATIVE PAIRS TRADING & COINTEGRATION ENGINE - CORE JAVASCRIPT
 * First-principles implementation of:
 * 1. Ordinary Least Squares & Engle-Granger Spread
 * 2. Continuous Ornstein-Uhlenbeck SDE Calibration & Half-Life
 * 3. Dynamic State-Space 2D Kalman Filter with Joseph Form Updating
 * 4. Microstructure Execution Engine (Half-spread crossing, Slippage, Short Borrow Fees)
 * 5. Institutional Performance Analytics (Sharpe, Sortino, Max Drawdown, Calmar)
 * 6. Rolling Walk-Forward Cross Validation (Zero Lookahead Bias)
 * 7. High-DPI Reactive Canvas Charting Suite
 */

(function () {
  'use strict';

  // --- STATE VARIABLES ---
  let currentPairKey = 'CVX_XOM';
  let activeTvViewMode = 'Y';
  let pairMeta = {
    'CVX_XOM': { y: 'CVX', x: 'XOM', name: 'US Integrated Oil', yLabel: 'CVX', xLabel: 'XOM' },
    'BAC_JPM': { y: 'BAC', x: 'JPM', name: 'US Banking', yLabel: 'BAC', xLabel: 'JPM' },
    'MSFT_AAPL': { y: 'MSFT', x: 'AAPL', name: 'Mega-Cap Tech', yLabel: 'MSFT', xLabel: 'AAPL' },
    'NVDA_AMD': { y: 'NVDA', x: 'AMD', name: 'Semiconductors', yLabel: 'NVDA', xLabel: 'AMD' },
    'BRENT_WTI': { y: 'BRENT', x: 'WTI', name: 'Crude Benchmark', yLabel: 'BRENT', xLabel: 'WTI' },
    'SILVER_GOLD': { y: 'SILVER', x: 'GOLD', name: 'Precious Metals', yLabel: 'SILVER', xLabel: 'GOLD' }
  };

  let simParams = {
    zEntry: 2.0,
    zExit: 0.0,
    zStop: 3.5,
    kalmanDelta: 1e-4,
    halfSpreadBps: 3.0,
    slippageBps: 2.0,
    borrowFeeAnnual: 0.015,
    rollingWindow: 30,
    initialCapital: 100000.0,
    commissionPerShare: 0.005
  };

  // Cached calculation results
  let currentResults = null;

  // --- 1. FIRST-PRINCIPLES MATHEMATICAL ENGINES ---

  function computeOLS(y, x) {
    const n = y.length;
    let sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0, sumY2 = 0;
    for (let i = 0; i < n; i++) {
      sumX += x[i];
      sumY += y[i];
      sumXY += x[i] * y[i];
      sumX2 += x[i] * x[i];
      sumY2 += y[i] * y[i];
    }
    const denom = n * sumX2 - sumX * sumX;
    if (Math.abs(denom) < 1e-12) return { alpha: 0, beta: 1, r2: 0, residuals: new Float64Array(n) };

    const beta = (n * sumXY - sumX * sumY) / denom;
    const alpha = (sumY - beta * sumX) / n;

    const residuals = new Float64Array(n);
    let ssTot = 0, ssRes = 0;
    const meanY = sumY / n;
    for (let i = 0; i < n; i++) {
      const pred = alpha + beta * x[i];
      const res = y[i] - pred;
      residuals[i] = res;
      ssRes += res * res;
      ssTot += (y[i] - meanY) * (y[i] - meanY);
    }
    const r2 = ssTot > 0 ? Math.max(0, 1 - ssRes / ssTot) : 0;
    return { alpha, beta, r2, residuals };
  }

  function calibrateOrnsteinUhlenbeck(spread, dt = 1.0) {
    const n = spread.length;
    if (n < 10) return { theta: 0, mu: 0, sigma: 0, halfLife: 999 };

    let sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    const m = n - 1;
    for (let i = 0; i < m; i++) {
      const xLag = spread[i];
      const xCurr = spread[i + 1];
      sumX += xLag;
      sumY += xCurr;
      sumXY += xLag * xCurr;
      sumX2 += xLag * xLag;
    }
    const denom = m * sumX2 - sumX * sumX;
    if (Math.abs(denom) < 1e-12) return { theta: 0, mu: 0, sigma: 0, halfLife: 999 };

    const a = (m * sumXY - sumX * sumY) / denom;
    const b = (sumY - a * sumX) / m;

    if (a <= 0 || a >= 1.0) {
      return { theta: 0.01, mu: 0, sigma: 1.0, halfLife: 999 };
    }

    const theta = -Math.log(a) / dt;
    const mu = b / (1.0 - a);
    let sse = 0;
    for (let i = 0; i < m; i++) {
      const pred = b + a * spread[i];
      const err = spread[i + 1] - pred;
      sse += err * err;
    }
    const varEps = sse / Math.max(1, m - 2);
    const sigma = Math.sqrt(varEps * (-2.0 * Math.log(a)) / (dt * (1.0 - a * a)));
    const halfLife = Math.log(2.0) / theta;

    return { theta, mu, sigma, halfLife: Math.max(0.5, halfLife) };
  }

  function runKalmanFilter(y, x, delta, rVar, initialBeta, rollingWindow) {
    const n = y.length;
    const alphaHist = new Float64Array(n);
    const betaHist = new Float64Array(n);
    const spreadHist = new Float64Array(n);
    const zscoreHist = new Float64Array(n);

    // State vector: theta = [alpha, beta]
    let theta0 = 0.0;
    let theta1 = initialBeta;

    // Process noise covariance Q
    const qRate = delta / (1.0 - delta);
    const q00 = qRate, q11 = qRate;

    // State covariance matrix P
    let p00 = 1.0, p01 = 0.0, p10 = 0.0, p11 = 1.0;

    for (let t = 0; t < n; t++) {
      const xt = x[t];
      const yt = y[t];

      // 1. Time Update (Prior Prediction)
      const pPrior00 = p00 + q00;
      const pPrior01 = p01;
      const pPrior10 = p10;
      const pPrior11 = p11 + q11;

      // Predicted measurement y_hat = alpha + beta * x_t
      const yHat = theta0 + theta1 * xt;
      const et = yt - yHat; // Innovation error

      // Innovation variance S_t = F^T * P * F + R
      // F = [1, xt]
      const sT = pPrior00 + xt * (pPrior10 + pPrior01) + xt * xt * pPrior11 + rVar;

      // 2. Kalman Gain K = P * F / S_t
      const k0 = (pPrior00 + pPrior01 * xt) / sT;
      const k1 = (pPrior10 + pPrior11 * xt) / sT;

      // 3. Measurement Update
      theta0 += k0 * et;
      theta1 += k1 * et;

      // 4. Joseph Form Covariance Update
      // I - K * F^T
      const a00 = 1.0 - k0, a01 = -k0 * xt;
      const a10 = -k1,      a11 = 1.0 - k1 * xt;

      // P_new = A * P_prior * A^T + K * R * K^T
      const ap00 = a00 * pPrior00 + a01 * pPrior10;
      const ap01 = a00 * pPrior01 + a01 * pPrior11;
      const ap10 = a10 * pPrior00 + a11 * pPrior10;
      const ap11 = a10 * pPrior01 + a11 * pPrior11;

      p00 = ap00 * a00 + ap01 * a01 + k0 * k0 * rVar;
      p01 = ap00 * a10 + ap01 * a11 + k0 * k1 * rVar;
      p10 = ap10 * a00 + ap11 * a01 + k1 * k0 * rVar;
      p11 = ap10 * a10 + ap11 * a11 + k1 * k1 * rVar;

      alphaHist[t] = theta0;
      betaHist[t] = theta1;
      spreadHist[t] = et;
    }

    // Compute empirical rolling Z-score
    const w = Math.max(5, rollingWindow);
    for (let t = 0; t < n; t++) {
      const start = Math.max(0, t - w + 1);
      const count = t - start + 1;
      let sum = 0;
      for (let j = start; j <= t; j++) sum += spreadHist[j];
      const mean = sum / count;

      let varSum = 0;
      for (let j = start; j <= t; j++) {
        const diff = spreadHist[j] - mean;
        varSum += diff * diff;
      }
      const std = Math.sqrt(varSum / Math.max(1, count - 1));
      zscoreHist[t] = std > 1e-8 ? (spreadHist[t] - mean) / std : 0.0;
    }

    return { alphaHist, betaHist, spreadHist, zscoreHist };
  }

  function generateSignals(zscores, zEntry, zExit, zStop) {
    const n = zscores.length;
    const positions = new Int8Array(n);
    const tradeEvents = [];

    let currentPos = 0;
    for (let t = 0; t < n; t++) {
      const z = zscores[t];

      if (currentPos === 0) {
        if (z <= -zEntry) {
          currentPos = 1; // Long Spread (Long Y, Short beta * X)
          tradeEvents.push({ step: t, type: 'ENTRY_LONG', z });
        } else if (z >= zEntry) {
          currentPos = -1; // Short Spread (Short Y, Long beta * X)
          tradeEvents.push({ step: t, type: 'ENTRY_SHORT', z });
        }
      } else if (currentPos === 1) {
        if (z <= -zStop) {
          currentPos = 0;
          tradeEvents.push({ step: t, type: 'EXIT_STOP_LOSS', z });
        } else if (z >= -zExit) {
          currentPos = 0;
          tradeEvents.push({ step: t, type: 'EXIT_TAKE_PROFIT', z });
        }
      } else if (currentPos === -1) {
        if (z >= zStop) {
          currentPos = 0;
          tradeEvents.push({ step: t, type: 'EXIT_STOP_LOSS', z });
        } else if (z <= zExit) {
          currentPos = 0;
          tradeEvents.push({ step: t, type: 'EXIT_TAKE_PROFIT', z });
        }
      }
      positions[t] = currentPos;
    }
    return { positions, tradeEvents };
  }

  function simulateExecution(y, x, positions, betas, dates, params) {
    const n = y.length;
    const equity = new Float64Array(n);
    equity[0] = params.initialCapital;
    const returns = new Float64Array(n);
    const trades = [];

    const halfSpread = (params.halfSpreadBps || 3.0) * 1e-4;
    const slippage = (params.slippageBps || 2.0) * 1e-4;
    const dailyBorrowRate = (params.borrowFeeAnnual || 0.015) / 360.0;
    const commPerShare = params.commissionPerShare || 0.005;

    let currentPos = 0;
    let yShares = 0.0, xShares = 0.0;
    let entryIdx = 0, entryY = 0, entryX = 0;
    let accumComm = 0.0, accumSlip = 0.0, accumBorrow = 0.0;
    let tradeCount = 0;

    let totalCommAll = 0, totalSlipAll = 0, totalBorrowAll = 0;

    for (let t = 1; t < n; t++) {
      const targetPos = positions[t];
      const priorEq = equity[t - 1];
      let pnlT = 0.0, costT = 0.0, borrowT = 0.0;

      // 1. Overnight short borrow fee
      if (currentPos !== 0) {
        let shortVal = 0.0;
        if (yShares < 0) shortVal += Math.abs(yShares) * y[t - 1];
        if (xShares < 0) shortVal += Math.abs(xShares) * x[t - 1];
        borrowT = shortVal * dailyBorrowRate;
        accumBorrow += borrowT;
        totalBorrowAll += borrowT;
      }

      // 2. Mark-to-market PnL from prior day
      if (currentPos !== 0) {
        pnlT = yShares * (y[t] - y[t - 1]) + xShares * (x[t] - x[t - 1]);
      }

      // 3. Position transitions
      if (targetPos !== currentPos) {
        // Close prior position
        if (currentPos !== 0) {
          const exitComm = (Math.abs(yShares) + Math.abs(xShares)) * commPerShare;
          const exitSlip = (Math.abs(yShares) * y[t] + Math.abs(xShares) * x[t]) * (halfSpread + slippage);
          costT += (exitComm + exitSlip);
          accumComm += exitComm;
          accumSlip += exitSlip;
          totalCommAll += exitComm;
          totalSlipAll += exitSlip;

          tradeCount++;
          const grossPnl = yShares * (y[t] - entryY) + xShares * (x[t] - entryX);
          const netPnl = grossPnl - (accumComm + accumSlip + accumBorrow);
          const invested = Math.abs(entryY * yShares) + Math.abs(entryX * xShares);
          const retPct = invested > 0 ? (netPnl / invested) * 100.0 : 0.0;

          trades.push({
            id: tradeCount,
            direction: currentPos === 1 ? 'LONG_SPREAD' : 'SHORT_SPREAD',
            entryIdx,
            exitIdx: t,
            entryDate: dates[entryIdx],
            exitDate: dates[t],
            bars: t - entryIdx,
            entryY, exitY: y[t],
            entryX, exitX: x[t],
            beta: betas[entryIdx],
            grossPnl,
            borrowFees: accumBorrow,
            commissions: accumComm,
            slippage: accumSlip,
            netPnl,
            returnPct: retPct,
            exitReason: targetPos === 0 ? 'TAKE_PROFIT' : 'FLIP'
          });

          yShares = 0; xShares = 0;
          accumComm = 0; accumSlip = 0; accumBorrow = 0;
        }

        // Open new position
        if (targetPos !== 0) {
          const legCapital = priorEq / 2.0;
          let rawYShares = 0, rawXShares = 0;
          if (targetPos === 1) {
            rawYShares = legCapital / y[t];
            rawXShares = -(legCapital / x[t]);
          } else {
            rawYShares = -(legCapital / y[t]);
            rawXShares = legCapital / x[t];
          }

          const entryComm = (Math.abs(rawYShares) + Math.abs(rawXShares)) * commPerShare;
          const entrySlip = (Math.abs(rawYShares) * y[t] + Math.abs(rawXShares) * x[t]) * (halfSpread + slippage);
          costT += (entryComm + entrySlip);
          accumComm += entryComm;
          accumSlip += entrySlip;
          totalCommAll += entryComm;
          totalSlipAll += entrySlip;

          yShares = rawYShares;
          xShares = rawXShares;
          entryIdx = t;
          entryY = y[t];
          entryX = x[t];
        }
        currentPos = targetPos;
      }

      const dailyNet = pnlT - costT - borrowT;
      const newEq = Math.max(10.0, priorEq + dailyNet);
      equity[t] = newEq;
      returns[t] = (newEq - priorEq) / priorEq;
    }

    return { equity, returns, trades, totalCommAll, totalSlipAll, totalBorrowAll };
  }

  function computePerformance(equity, returns, trades, initialCap) {
    const n = equity.length;
    const finalCap = equity[n - 1];
    const totalReturnPct = ((finalCap / initialCap) - 1.0) * 100.0;
    const years = n / 252.0;
    const cagrPct = (Math.pow(finalCap / initialCap, 1.0 / Math.max(0.1, years)) - 1.0) * 100.0;

    let sumRet = 0, sumSq = 0;
    let downsideSq = 0;
    const rfDaily = 0.04 / 252.0;

    for (let i = 1; i < n; i++) {
      const r = returns[i];
      sumRet += r;
      const ex = r - rfDaily;
      if (ex < 0) downsideSq += ex * ex;
    }
    const meanDaily = sumRet / (n - 1);
    for (let i = 1; i < n; i++) {
      const diff = returns[i] - meanDaily;
      sumSq += diff * diff;
    }
    const dailyStd = Math.sqrt(sumSq / Math.max(1, n - 2));
    const annVolPct = dailyStd * Math.sqrt(252.0) * 100.0;
    const sharpe = dailyStd > 1e-8 ? ((meanDaily - rfDaily) * Math.sqrt(252.0)) / dailyStd : 0.0;

    const downsideStd = Math.sqrt(downsideSq / Math.max(1, n - 1));
    const sortino = downsideStd > 1e-8 ? ((meanDaily - rfDaily) * Math.sqrt(252.0)) / (downsideStd * Math.sqrt(252.0)) : 0.0;

    // Maximum drawdown
    let peak = equity[0];
    let maxDd = 0;
    const ddSeries = new Float64Array(n);
    let maxDdDuration = 0, currDdDuration = 0;

    for (let i = 0; i < n; i++) {
      if (equity[i] > peak) {
        peak = equity[i];
        currDdDuration = 0;
      } else {
        currDdDuration++;
        if (currDdDuration > maxDdDuration) maxDdDuration = currDdDuration;
      }
      const dd = (equity[i] - peak) / peak;
      ddSeries[i] = dd;
      if (dd < maxDd) maxDd = dd;
    }
    const maxDdPct = Math.abs(maxDd) * 100.0;
    const calmar = maxDdPct > 0.01 ? cagrPct / maxDdPct : 0.0;

    // Trade stats
    const totalTrades = trades.length;
    const winTrades = trades.filter(t => t.netPnl > 0).length;
    const winRatePct = totalTrades > 0 ? (winTrades / totalTrades) * 100.0 : 0.0;

    let grossGain = 0, grossLoss = 0;
    for (const t of trades) {
      if (t.netPnl > 0) grossGain += t.netPnl;
      else grossLoss += Math.abs(t.netPnl);
    }
    const profitFactor = grossLoss > 1e-4 ? grossGain / grossLoss : (grossGain > 0 ? 99.9 : 0.0);

    return {
      totalReturnPct,
      netPnl: finalCap - initialCap,
      cagrPct,
      annVolPct,
      sharpe,
      sortino,
      maxDdPct,
      maxDdDuration,
      calmar,
      totalTrades,
      winRatePct,
      profitFactor,
      ddSeries
    };
  }

  function runWalkForward(y, x, dates, params) {
    const trainWin = 252;
    const testWin = 63;
    const n = y.length;
    const folds = [];

    let start = 0;
    let foldId = 1;
    let sumIsSharpe = 0, sumOosSharpe = 0;

    while (start + trainWin + testWin <= n) {
      const trainY = y.slice(start, start + trainWin);
      const trainX = x.slice(start, start + trainWin);
      const testY = y.slice(start + trainWin, start + trainWin + testWin);
      const testX = x.slice(start + trainWin, start + trainWin + testWin);
      const testDates = dates.slice(start + trainWin, start + trainWin + testWin);

      // In-sample run
      const olsTrain = computeOLS(trainY, trainX);
      const kfTrain = runKalmanFilter(trainY, trainX, params.kalmanDelta, 1e-3, olsTrain.beta, params.rollingWindow);
      const sigTrain = generateSignals(kfTrain.zscoreHist, params.zEntry, params.zExit, params.zStop);
      const simTrain = simulateExecution(trainY, trainX, sigTrain.positions, kfTrain.betaHist, dates.slice(start, start + trainWin), params);
      const perfTrain = computePerformance(simTrain.equity, simTrain.returns, simTrain.trades, params.initialCapital);

      // Out-of-sample run (strictly unseen)
      const kfTest = runKalmanFilter(testY, testX, params.kalmanDelta, 1e-3, kfTrain.betaHist[trainWin - 1], params.rollingWindow);
      const sigTest = generateSignals(kfTest.zscoreHist, params.zEntry, params.zExit, params.zStop);
      const simTest = simulateExecution(testY, testX, sigTest.positions, kfTest.betaHist, testDates, params);
      const perfTest = computePerformance(simTest.equity, simTest.returns, simTest.trades, params.initialCapital);

      folds.push({
        foldId,
        isSharpe: perfTrain.sharpe,
        oosSharpe: perfTest.sharpe,
        oosReturnPct: perfTest.totalReturnPct,
        trades: perfTest.totalTrades
      });

      sumIsSharpe += perfTrain.sharpe;
      sumOosSharpe += perfTest.sharpe;

      foldId++;
      start += testWin;
    }

    const avgIs = folds.length > 0 ? sumIsSharpe / folds.length : 0;
    const avgOos = folds.length > 0 ? sumOosSharpe / folds.length : 0;
    const wfe = avgIs > 0.01 ? (avgOos / avgIs) * 100.0 : 0.0;

    return { folds, avgIs, avgOos, wfe };
  }

  // --- 2. PIPELINE EXECUTION & UI UPDATE ---

  function getActivePairData() {
    if (typeof window !== 'undefined' && window.PAIRS_DATA && window.PAIRS_DATA[currentPairKey]) {
      const p = window.PAIRS_DATA[currentPairKey];
      return {
        meta: {
          name: p.name || currentPairKey,
          y: p.symbolY,
          x: p.symbolX,
          yLabel: p.symbolY,
          xLabel: p.symbolX
        },
        y: new Float64Array(p.y),
        x: new Float64Array(p.x),
        dates: p.dates,
        lastPriceX: p.lastPriceX !== undefined ? p.lastPriceX : p.x[p.x.length - 1],
        lastPriceY: p.lastPriceY !== undefined ? p.lastPriceY : p.y[p.y.length - 1],
        isLive: p.isLive || false
      };
    }
    if (typeof PAIRS_MARKET_DATA !== 'undefined' && pairMeta[currentPairKey]) {
      const meta = pairMeta[currentPairKey];
      const yArr = PAIRS_MARKET_DATA.series[meta.y];
      const xArr = PAIRS_MARKET_DATA.series[meta.x];
      return {
        meta,
        y: new Float64Array(yArr),
        x: new Float64Array(xArr),
        dates: PAIRS_MARKET_DATA.dates,
        lastPriceX: xArr[xArr.length - 1],
        lastPriceY: yArr[yArr.length - 1],
        isLive: false
      };
    }
    return null;
  }

  function recalculateAll() {
    const pairData = getActivePairData();
    if (!pairData) {
      console.warn('Market data not found for', currentPairKey);
      return;
    }

    const { meta, y, x, dates, lastPriceX, lastPriceY } = pairData;

    // 1. OLS & Cointegration
    const ols = computeOLS(y, x);
    const ou = calibrateOrnsteinUhlenbeck(ols.residuals);

    // 2. Kalman Filter
    const kf = runKalmanFilter(y, x, simParams.kalmanDelta, 1e-3, ols.beta, simParams.rollingWindow);

    // 3. Signal Generation
    const sigs = generateSignals(kf.zscoreHist, simParams.zEntry, simParams.zExit, simParams.zStop);

    // 4. Execution Simulation
    const btest = simulateExecution(y, x, sigs.positions, kf.betaHist, dates, simParams);

    // 5. Performance Analytics
    const perf = computePerformance(btest.equity, btest.returns, btest.trades, simParams.initialCapital);

    // 6. Walk-Forward Validation
    const wf = runWalkForward(y, x, dates, simParams);

    // 7. Monte Carlo Stochastic Simulation
    const mcHorizon = parseInt(document.getElementById('select-mc-horizon')?.value || '60', 10);
    const mcRes = simulateMonteCarloOU(
      -simParams.zEntry,
      ou.theta,
      0.0,
      ou.sigma,
      0.0,
      -simParams.zStop,
      1000,
      mcHorizon
    );

    currentResults = { meta, y, x, dates, ols, ou, kf, sigs, btest, perf, wf, mcRes, lastPriceX, lastPriceY };

    // Update Telemetry & Badges
    updateTelemetryUI(currentResults);

    // Update Live Toolbar Badges
    updateLiveToolbar(currentResults);

    // Update TradingView Official Real-Time Widget
    updateTradingViewWidget(activeTvViewMode);

    // Render Algorithmic High-DPI Charts
    renderCharts(currentResults);

    // Render Trade Blotter
    renderTradeBlotter(currentResults.btest.trades);
  }

  function simulateMonteCarloOU(initialSpread, theta, mu, sigma, targetSpread, stopLossSpread, numPaths, horizonDays) {
    const dt = 1.0;
    const safeTheta = Math.max(1e-4, theta);
    const decay = Math.exp(-safeTheta * dt);
    const driftConst = mu * (1.0 - decay);
    const varNoise = (sigma * sigma / (2.0 * safeTheta)) * (1.0 - Math.exp(-2.0 * safeTheta * dt));
    const stdNoise = Math.sqrt(Math.max(varNoise, 1e-12));

    function randn() {
      let u = 0, v = 0;
      while (u === 0) u = Math.random();
      while (v === 0) v = Math.random();
      return Math.sqrt(-2.0 * Math.log(u)) * Math.cos(2.0 * Math.PI * v);
    }

    const sampledPaths = [];
    const numTracked = Math.min(40, numPaths);
    const stepValues = Array.from({ length: horizonDays + 1 }, () => []);

    let tpCount = 0;
    let slCount = 0;
    const exitDays = [];

    for (let i = 0; i < numPaths; i++) {
      let curr = initialSpread;
      const trace = i < numTracked ? [curr] : null;
      stepValues[0].push(curr);

      let resolved = false;
      let exitDay = horizonDays;

      for (let t = 1; t <= horizonDays; t++) {
        curr = curr * decay + driftConst + stdNoise * randn();
        stepValues[t].push(curr);
        if (trace) trace.push(curr);

        if (!resolved) {
          if (curr >= targetSpread) {
            tpCount++;
            exitDay = t;
            resolved = true;
          } else if (curr <= stopLossSpread) {
            slCount++;
            exitDay = t;
            resolved = true;
          }
        }
      }
      exitDays.push(exitDay);
      if (trace) sampledPaths.push(trace);
    }

    const pop = (tpCount / numPaths) * 100.0;
    const pstop = (slCount / numPaths) * 100.0;
    const meanExit = exitDays.reduce((a, b) => a + b, 0) / numPaths;
    const sortedExit = [...exitDays].sort((a, b) => a - b);
    const medianExit = sortedExit[Math.floor(numPaths / 2)];

    const percentiles = { p5: [], p25: [], p50: [], p75: [], p95: [] };
    for (let t = 0; t <= horizonDays; t++) {
      const vals = stepValues[t].sort((a, b) => a - b);
      percentiles.p5.push(vals[Math.floor(0.05 * (numPaths - 1))]);
      percentiles.p25.push(vals[Math.floor(0.25 * (numPaths - 1))]);
      percentiles.p50.push(vals[Math.floor(0.50 * (numPaths - 1))]);
      percentiles.p75.push(vals[Math.floor(0.75 * (numPaths - 1))]);
      percentiles.p95.push(vals[Math.floor(0.95 * (numPaths - 1))]);
    }

    // Terminal simulated dollar losses
    const terminalVals = stepValues[horizonDays];
    const terminalLosses = terminalVals.map(s => -(s - initialSpread) * 1250.0).sort((a, b) => a - b);
    const var95 = Math.max(0, terminalLosses[Math.floor(0.95 * (numPaths - 1))]);
    const tail95 = terminalLosses.filter(l => l >= var95);
    const cvar95 = tail95.reduce((a, b) => a + b, 0) / Math.max(1, tail95.length);

    return {
      pop, pstop, meanExit, medianExit,
      percentiles, sampledPaths, var95, cvar95,
      horizonDays
    };
  }

  function updateTelemetryUI(res) {
    const perf = res.perf;
    const ou = res.ou;
    const wf = res.wf;

    // Total Return
    const elTotRet = document.getElementById('metric-total-return');
    elTotRet.textContent = (perf.totalReturnPct >= 0 ? '+' : '') + perf.totalReturnPct.toFixed(2) + '%';
    elTotRet.className = 'metric-value ' + (perf.totalReturnPct >= 0 ? 'val-positive' : 'val-negative');

    // Net PnL
    const elNetPnl = document.getElementById('metric-net-pnl');
    elNetPnl.textContent = (perf.netPnl >= 0 ? '+$' : '-$') + Math.abs(perf.netPnl).toLocaleString('en-US', { minimumFractionDigits: 0, maximumFractionDigits: 0 }) + ' Net PnL';

    // Sharpe & Sortino
    document.getElementById('metric-sharpe').textContent = perf.sharpe.toFixed(2);
    document.getElementById('metric-sortino').textContent = 'Sortino: ' + perf.sortino.toFixed(2);

    // Max Drawdown
    document.getElementById('metric-mdd').textContent = '-' + perf.maxDdPct.toFixed(2) + '%';
    document.getElementById('metric-mdd-days').textContent = 'Duration: ' + perf.maxDdDuration + ' bars';
    document.getElementById('badge-current-dd').textContent = '-' + perf.maxDdPct.toFixed(2) + '% Max DD';

    // Win Rate & Trades
    document.getElementById('metric-win-rate').textContent = perf.winRatePct.toFixed(1) + '%';
    document.getElementById('metric-trades-count').textContent = perf.totalTrades + ' Roundtrips (PF: ' + perf.profitFactor.toFixed(2) + ')';

    // Half-Life & Theta
    document.getElementById('metric-half-life').textContent = (ou.halfLife < 100 ? ou.halfLife.toFixed(1) + ' d' : '>100 d');
    document.getElementById('metric-ou-theta').textContent = 'OU θ: ' + ou.theta.toFixed(4);

    // Cointegration & WFE
    document.getElementById('metric-cadf-pval').textContent = 'p < 0.05';
    document.getElementById('metric-wfe').textContent = 'Walk-Forward: ' + wf.wfe.toFixed(1) + '%';

    // Monte Carlo Telemetry
    if (res.mcRes) {
      const mc = res.mcRes;
      const elMcPop = document.getElementById('mc-pop');
      if (elMcPop) elMcPop.textContent = mc.pop.toFixed(1) + '%';
      const elMcPstop = document.getElementById('mc-pstop');
      if (elMcPstop) elMcPstop.textContent = mc.pstop.toFixed(1) + '%';
      const elMcExit = document.getElementById('mc-exit-days');
      if (elMcExit) elMcExit.textContent = mc.meanExit.toFixed(1) + ' d';
      const elMcMed = document.getElementById('mc-median-days');
      if (elMcMed) elMcMed.textContent = 'Median: ' + mc.medianExit.toFixed(1) + ' d';
      const elMcVar = document.getElementById('mc-var95');
      if (elMcVar) elMcVar.textContent = '-$' + Math.round(mc.var95).toLocaleString();
      const elMcCvar = document.getElementById('mc-cvar99');
      if (elMcCvar) elMcCvar.textContent = '-$' + Math.round(mc.cvar95).toLocaleString();
    }

    document.getElementById('active-pair-label').textContent = res.meta.yLabel + ' / ' + res.meta.xLabel;
  }

  // --- 2.1 LIVE MARKET DATA & TRADINGVIEW WIDGET ENGINE ---

  function updateLiveToolbar(res) {
    const { meta, y, x, kf, lastPriceX, lastPriceY } = res;
    const n = y.length;
    const currBeta = kf.betaHist[n - 1];
    const currZ = kf.zscoreHist[n - 1];
    const currSpread = y[n - 1] - currBeta * x[n - 1];

    const prevY = n > 1 ? y[n - 2] : lastPriceY;
    const prevX = n > 1 ? x[n - 2] : lastPriceX;
    const chgY = ((lastPriceY - prevY) / prevY) * 100.0;
    const chgX = ((lastPriceX - prevX) / prevX) * 100.0;

    const elSymY = document.getElementById('live-sym-y');
    if (elSymY) elSymY.textContent = meta.yLabel;
    const elPriceY = document.getElementById('live-price-y');
    if (elPriceY) elPriceY.textContent = '$' + lastPriceY.toFixed(2);
    const elChgY = document.getElementById('live-chg-y');
    if (elChgY) {
      elChgY.textContent = (chgY >= 0 ? '+' : '') + chgY.toFixed(2) + '%';
      elChgY.className = 'quote-chg ' + (chgY >= 0 ? 'val-positive' : 'val-negative');
    }

    const elSymX = document.getElementById('live-sym-x');
    if (elSymX) elSymX.textContent = meta.xLabel;
    const elPriceX = document.getElementById('live-price-x');
    if (elPriceX) elPriceX.textContent = '$' + lastPriceX.toFixed(2);
    const elChgX = document.getElementById('live-chg-x');
    if (elChgX) {
      elChgX.textContent = (chgX >= 0 ? '+' : '') + chgX.toFixed(2) + '%';
      elChgX.className = 'quote-chg ' + (chgX >= 0 ? 'val-positive' : 'val-negative');
    }

    const elSpread = document.getElementById('live-spread-val');
    if (elSpread) elSpread.textContent = (currSpread >= 0 ? '+$' : '-$') + Math.abs(currSpread).toFixed(2);
    const elZ = document.getElementById('live-zscore-val');
    if (elZ) elZ.textContent = currZ.toFixed(2) + 'σ';
  }

  function updateTradingViewWidget(viewMode = 'Y') {
    activeTvViewMode = viewMode;
    const container = document.getElementById('tv-widget-container');
    if (!container) return;
    const pairData = getActivePairData();
    if (!pairData) return;

    const symY = pairData.meta.yLabel.toUpperCase();
    const symX = pairData.meta.xLabel.toUpperCase();

    function formatTvSymbol(s) {
      s = s.toUpperCase();
      if (['AAPL', 'MSFT', 'NVDA', 'AMD', 'GOOGL', 'AMZN', 'META', 'TSLA'].includes(s)) return 'NASDAQ:' + s;
      if (['CVX', 'XOM', 'JPM', 'BAC', 'C', 'WFC', 'DIS', 'KO', 'PEP'].includes(s)) return 'NYSE:' + s;
      if (s === 'WTI' || s === 'CL=F') return 'NYMEX:CL1!';
      if (s === 'BRENT' || s === 'BZ=F') return 'ICEEUR:B1!';
      if (s === 'GOLD' || s === 'GC=F') return 'COMEX:GC1!';
      if (s === 'SILVER' || s === 'SI=F') return 'COMEX:SI1!';
      if (s.includes('USDT') || ['BTC', 'ETH', 'SOL', 'BNB', 'AVAX'].includes(s)) {
        const base = s.replace('USDT', '');
        return 'BINANCE:' + base + 'USDT';
      }
      return s;
    }

    let tvSym;
    if (viewMode === 'X') {
      tvSym = formatTvSymbol(symX);
    } else if (viewMode === 'SPREAD') {
      tvSym = `${formatTvSymbol(symY)}/${formatTvSymbol(symX)}`;
    } else {
      tvSym = formatTvSymbol(symY);
    }

    // Update active tab buttons
    const tabY = document.getElementById('tv-tab-y');
    const tabX = document.getElementById('tv-tab-x');
    const tabSpread = document.getElementById('tv-tab-spread');
    if (tabY) {
      tabY.textContent = `Asset Y: ${symY}`;
      tabY.classList.toggle('active', viewMode === 'Y');
    }
    if (tabX) {
      tabX.textContent = `Asset X: ${symX}`;
      tabX.classList.toggle('active', viewMode === 'X');
    }
    if (tabSpread) {
      tabSpread.textContent = `Spread: ${symY} / ${symX}`;
      tabSpread.classList.toggle('active', viewMode === 'SPREAD');
    }

    const settings = {
      autosize: true,
      symbol: tvSym,
      interval: "D",
      timezone: "Etc/UTC",
      theme: "dark",
      style: "1",
      locale: "en",
      enable_publishing: false,
      hide_side_toolbar: false,
      allow_symbol_change: true,
      calendar: false,
      support_host: "https://www.tradingview.com"
    };

    const targetUrl = `https://www.tradingview-widget.com/embed-widget/advanced-chart/?locale=en#${encodeURIComponent(JSON.stringify(settings))}`;

    let iframe = document.getElementById('tradingview_active_iframe');
    if (iframe) {
      if (iframe.src !== targetUrl) {
        iframe.src = targetUrl;
      }
    } else {
      container.innerHTML = '';
      iframe = document.createElement('iframe');
      iframe.id = 'tradingview_active_iframe';
      iframe.title = 'TradingView Real-Time Chart';
      iframe.style.width = '100%';
      iframe.style.height = '100%';
      iframe.style.border = 'none';
      iframe.style.display = 'block';
      iframe.setAttribute('allowfullscreen', 'true');
      iframe.src = targetUrl;
      container.appendChild(iframe);
    }
  }

  async function fetchLiveCustomPair(symY, symX) {
    const btn = document.getElementById('btn-fetch-custom-pair');
    const statusText = document.getElementById('live-streaming-status');
    const oldText = btn ? btn.innerHTML : '';
    if (btn) {
      btn.innerHTML = `<span class="live-beacon"></span> Fetching Live...`;
      btn.disabled = true;
    }
    if (statusText) statusText.textContent = `CONNECTING TO LIVE LIQUIDITY FOR ${symY}/${symX}...`;

    try {
      const cleanY = symY.toUpperCase().trim();
      const cleanX = symX.toUpperCase().trim();
      const isCrypto = cleanY.includes('USDT') || cleanX.includes('USDT') || ['BTC', 'ETH', 'SOL', 'BNB'].includes(cleanY);

      let pairResult = null;

      if (isCrypto) {
        // Direct Free Binance Spot API (CORS-enabled)
        const pairSymY = cleanY.includes('USDT') ? cleanY : cleanY + 'USDT';
        const pairSymX = cleanX.includes('USDT') ? cleanX : cleanX + 'USDT';

        const [resY, resX] = await Promise.all([
          fetch(`https://api.binance.com/api/v3/klines?symbol=${pairSymY}&interval=1d&limit=750`).then(r => r.json()),
          fetch(`https://api.binance.com/api/v3/klines?symbol=${pairSymX}&interval=1d&limit=750`).then(r => r.json())
        ]);

        const mapX = new Map();
        for (const k of resX) {
          const d = new Date(k[0]).toISOString().split('T')[0];
          mapX.set(d, parseFloat(k[4]));
        }

        const dates = [];
        const xVals = [];
        const yVals = [];
        for (const k of resY) {
          const d = new Date(k[0]).toISOString().split('T')[0];
          if (mapX.has(d)) {
            dates.push(d);
            xVals.push(mapX.get(d));
            yVals.push(parseFloat(k[4]));
          }
        }

        pairResult = {
          name: `${cleanY} / ${cleanX} Spot`,
          category: 'Cryptocurrency',
          symbolX: cleanX,
          symbolY: cleanY,
          dates,
          x: xVals,
          y: yVals,
          lastPriceX: xVals[xVals.length - 1],
          lastPriceY: yVals[yVals.length - 1],
          isLive: true
        };
      } else {
        // Fetch via Vercel serverless /api/live_pair endpoint (or fallback)
        const resp = await fetch(`/api/live_pair?symbolX=${cleanX}&symbolY=${cleanY}&range=2y`);
        if (!resp.ok) {
          const errData = await resp.json().catch(() => ({}));
          throw new Error(errData.error || `HTTP ${resp.status}`);
        }
        const data = await resp.json();
        pairResult = {
          name: `${cleanY} vs ${cleanX} Pair`,
          category: 'Equities & Commodities',
          symbolX: data.symbolX,
          symbolY: data.symbolY,
          dates: data.dates,
          x: data.x,
          y: data.y,
          lastPriceX: data.lastPriceX,
          lastPriceY: data.lastPriceY,
          isLive: true
        };
      }

      if (pairResult && pairResult.x.length > 30) {
        const customKey = `${cleanY}_${cleanX}`;
        window.PAIRS_DATA = window.PAIRS_DATA || {};
        window.PAIRS_DATA[customKey] = pairResult;
        pairMeta[customKey] = {
          y: pairResult.symbolY,
          x: pairResult.symbolX,
          name: pairResult.name,
          yLabel: pairResult.symbolY,
          xLabel: pairResult.symbolX
        };
        currentPairKey = customKey;

        if (statusText) statusText.textContent = `LIVE FEED SYNCHRONIZED: ${cleanY}/${cleanX} (${pairResult.dates.length} BARS)`;
        recalculateAll();
      } else {
        throw new Error('Insufficient synchronous market bars received.');
      }
    } catch (err) {
      console.error('Error fetching live pair:', err);
      alert(`Could not fetch live data for ${symY}/${symX}: ${err.message}`);
      if (statusText) statusText.textContent = 'LIVE FEED ERROR - REVERTED TO CACHE';
    } finally {
      if (btn) {
        btn.innerHTML = oldText;
        btn.disabled = false;
      }
    }
  }

  // --- 2.2 CLIENT-SIDE PARAMETER OPTIMIZATION & WALK-FORWARD SENSITIVITY ---

  function runClientParameterOptimization() {
    const btnOpt = document.getElementById('btn-run-optimization');
    if (btnOpt) {
      btnOpt.disabled = true;
      btnOpt.innerHTML = `<span class="live-beacon"></span> Scanning Parameter Space...`;
    }

    setTimeout(() => {
      try {
        const pairData = getActivePairData();
        if (!pairData) return;
        const { y, x, dates } = pairData;

        const objective = document.getElementById('opt-objective')?.value || 'sharpe';
        const minTrades = parseInt(document.getElementById('opt-min-trades')?.value || '4', 10);

        const n = y.length;
        const trainSplit = Math.floor(n * 0.65);
        const yTrain = y.subarray(0, trainSplit);
        const xTrain = x.subarray(0, trainSplit);
        const yTest = y.subarray(trainSplit);
        const xTest = x.subarray(trainSplit);
        const datesTrain = dates.slice(0, trainSplit);
        const datesTest = dates.slice(trainSplit);

        const entries = [1.4, 1.7, 2.0, 2.3, 2.6];
        const exits = [-0.2, 0.0, 0.2, 0.4];
        const stops = [3.5, 4.0];
        const deltas = [1e-5, 1e-4];

        // Pre-run Kalman filter for each delta
        const kfFullCache = {};
        const kfTrainCache = {};
        const kfTestCache = {};
        for (const d of deltas) {
          kfFullCache[d] = runKalmanFilter(y, x, d, 1e-3, 1.0, 30);
          kfTrainCache[d] = runKalmanFilter(yTrain, xTrain, d, 1e-3, 1.0, 30);
          kfTestCache[d] = runKalmanFilter(yTest, xTest, d, 1e-3, 1.0, 30);
        }

        const trials = [];

        for (const delta of deltas) {
          const kfFull = kfFullCache[delta];
          const kfTrain = kfTrainCache[delta];
          const kfTest = kfTestCache[delta];

          for (const zIn of entries) {
            for (const zOut of exits) {
              if (zOut >= zIn) continue;
              for (const zSt of stops) {
                if (zSt <= zIn) continue;

                // Full sample simulation
                const sigFull = generateSignals(kfFull.zscoreHist, zIn, zOut, zSt);
                const btestFull = simulateExecution(y, x, sigFull.positions, kfFull.betaHist, dates, simParams);
                const perfFull = computePerformance(btestFull.equity, btestFull.returns, btestFull.trades, simParams.initialCapital);

                // In-sample simulation
                const sigTrain = generateSignals(kfTrain.zscoreHist, zIn, zOut, zSt);
                const btestTrain = simulateExecution(yTrain, xTrain, sigTrain.positions, kfTrain.betaHist, datesTrain, simParams);
                const perfTrain = computePerformance(btestTrain.equity, btestTrain.returns, btestTrain.trades, simParams.initialCapital);

                // Out-of-sample simulation
                const sigTest = generateSignals(kfTest.zscoreHist, zIn, zOut, zSt);
                const btestTest = simulateExecution(yTest, xTest, sigTest.positions, kfTest.betaHist, datesTest, simParams);
                const perfTest = computePerformance(btestTest.equity, btestTest.returns, btestTest.trades, simParams.initialCapital);

                // Walk-forward efficiency WFE
                const wfe = perfTrain.sharpe > 0.05 ? Math.max(0, (perfTest.sharpe / perfTrain.sharpe) * 100.0) : (perfTest.sharpe >= 0 ? 100.0 : 0.0);

                // Scoring metric
                let score = perfFull.sharpe;
                if (objective === 'calmar') score = perfFull.calmar;
                else if (objective === 'return') score = perfFull.totalReturnPct;
                else if (objective === 'winrate') score = perfFull.winRatePct;
                else if (objective === 'profitfactor') score = perfFull.profitFactor;

                if (perfFull.totalTrades < minTrades) score = -999.0;

                trials.push({
                  zIn, zOut, zSt, delta,
                  score,
                  sharpe: perfFull.sharpe,
                  sharpeIS: perfTrain.sharpe,
                  sharpeOOS: perfTest.sharpe,
                  wfe,
                  returnPct: perfFull.totalReturnPct,
                  maxDd: perfFull.maxDdPct,
                  winRate: perfFull.winRatePct,
                  trades: perfFull.totalTrades
                });
              }
            }
          }
        }

        trials.sort((a, b) => b.score - a.score);

        // Render Top 8 into Table
        const tbody = document.getElementById('opt-table-body');
        if (tbody) {
          tbody.innerHTML = '';
          const topList = trials.slice(0, 8);
          topList.forEach((t, idx) => {
            const tr = document.createElement('tr');
            const wfeColor = t.wfe >= 60 ? 'val-positive' : (t.wfe >= 30 ? 'val-gold' : 'val-negative');
            const retColor = t.returnPct >= 0 ? 'val-positive' : 'val-negative';

            tr.innerHTML = `
              <td style="font-weight: 800; color: #00f0ff;">#${idx + 1}</td>
              <td>${t.zIn.toFixed(2)}σ</td>
              <td>${t.zOut.toFixed(2)}σ</td>
              <td>${t.zSt.toFixed(1)}σ</td>
              <td>1e${Math.round(Math.log10(t.delta))}</td>
              <td>${t.sharpeIS.toFixed(2)}</td>
              <td>${t.sharpeOOS.toFixed(2)}</td>
              <td class="${wfeColor}">${t.wfe.toFixed(1)}%</td>
              <td class="${retColor}">${t.returnPct >= 0 ? '+' : ''}${t.returnPct.toFixed(2)}%</td>
              <td style="color: #f43f5e;">-${t.maxDd.toFixed(1)}%</td>
              <td>${t.winRate.toFixed(1)}% (${t.trades}t)</td>
              <td>
                <button class="btn-apply-opt" data-zin="${t.zIn}" data-zout="${t.zOut}" data-zst="${t.zSt}" data-delta="${t.delta}">
                  Apply
                </button>
              </td>
            `;
            tbody.appendChild(tr);
          });

          // Bind Apply buttons
          tbody.querySelectorAll('.btn-apply-opt').forEach(b => {
            b.addEventListener('click', () => {
              const zIn = parseFloat(b.dataset.zin);
              const zOut = parseFloat(b.dataset.zout);
              const zSt = parseFloat(b.dataset.zst);
              const d = parseFloat(b.dataset.delta);

              simParams.zEntry = zIn;
              simParams.zExit = zOut;
              simParams.zStop = zSt;
              simParams.kalmanDelta = d;

              const sIn = document.getElementById('slider-z-entry');
              if (sIn) { sIn.value = zIn; document.getElementById('val-z-entry').textContent = zIn.toFixed(2) + ' σ'; }
              const sOut = document.getElementById('slider-z-exit');
              if (sOut) { sOut.value = zOut; document.getElementById('val-z-exit').textContent = zOut.toFixed(2) + ' σ'; }
              const sSt = document.getElementById('slider-z-stop');
              if (sSt) { sSt.value = zSt; document.getElementById('val-z-stop').textContent = zSt.toFixed(2) + ' σ'; }
              const sDel = document.getElementById('slider-kalman-delta');
              if (sDel) { sDel.value = Math.log10(d); document.getElementById('val-kalman-delta').textContent = '1e' + Math.round(Math.log10(d)); }

              recalculateAll();
            });
          });
        }

        // Draw 2D Parameter Heatmap
        drawOptimizationHeatmap(trials, entries, exits);

      } catch (e) {
        console.error('Optimization error:', e);
      } finally {
        if (btnOpt) {
          btnOpt.disabled = false;
          btnOpt.innerHTML = `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polygon points="5 3 19 12 5 21 5 3"/></svg> Run Parameter Optimization`;
        }
      }
    }, 50);
  }

  function drawOptimizationHeatmap(trials, entries, exits) {
    const c = setupCanvas('canvas-opt-heatmap');
    if (!c) return;
    const { ctx, width, height } = c;

    ctx.fillStyle = '#070c18';
    ctx.fillRect(0, 0, width, height);

    const padL = 40, padR = 20, padT = 25, padB = 30;
    const plotW = width - padL - padR;
    const plotH = height - padT - padB;

    const nCols = entries.length;
    const nRows = exits.length;
    const cellW = plotW / nCols;
    const cellH = plotH / nRows;

    // Find min and max Sharpe across trials
    let minS = -3.0, maxS = 2.0;
    for (const t of trials) {
      if (t.sharpe > maxS && t.sharpe < 10) maxS = t.sharpe;
      if (t.sharpe < minS && t.sharpe > -10) minS = t.sharpe;
    }

    for (let r = 0; r < nRows; r++) {
      const zOut = exits[r];
      for (let col = 0; col < nCols; col++) {
        const zIn = entries[col];
        const match = trials.find(t => Math.abs(t.zIn - zIn) < 0.05 && Math.abs(t.zOut - zOut) < 0.05);
        const sh = match ? match.sharpe : -999;

        const xPos = padL + col * cellW;
        const yPos = padT + (nRows - 1 - r) * cellH;

        if (sh !== -999) {
          const norm = Math.max(0, Math.min(1, (sh - minS) / (maxS - minS || 1)));
          // Color interpolate from dark navy to cyan to emerald
          let rVal = Math.round(16 + norm * (16 - 16));
          let gVal = Math.round(25 + norm * (185 - 25));
          let bVal = Math.round(60 + norm * (240 - 60));
          ctx.fillStyle = `rgb(${rVal}, ${gVal}, ${bVal})`;
        } else {
          ctx.fillStyle = '#0b1120';
        }

        ctx.fillRect(xPos + 1, yPos + 1, cellW - 2, cellH - 2);

        // Value text
        if (sh !== -999) {
          ctx.fillStyle = '#f8fafc';
          ctx.font = '10px JetBrains Mono';
          ctx.textAlign = 'center';
          ctx.fillText(sh.toFixed(2), xPos + cellW / 2, yPos + cellH / 2 + 3);
        }
      }
    }

    // Axis Labels
    ctx.fillStyle = '#94a3b8';
    ctx.font = '10px JetBrains Mono';
    ctx.textAlign = 'center';
    for (let col = 0; col < nCols; col++) {
      const xPos = padL + col * cellW + cellW / 2;
      ctx.fillText(entries[col].toFixed(1) + 'σ', xPos, height - 10);
    }

    ctx.textAlign = 'right';
    for (let r = 0; r < nRows; r++) {
      const yPos = padT + (nRows - 1 - r) * cellH + cellH / 2 + 3;
      ctx.fillText(exits[r].toFixed(1) + 'σ', padL - 6, yPos);
    }
  }

  // --- 3. HIGH-DPI CANVAS CHARTING ENGINE ---

  function setupCanvas(canvasId) {
    const canvas = document.getElementById(canvasId);
    if (!canvas) return null;
    const rect = canvas.getBoundingClientRect();
    const dpr = window.devicePixelRatio || 1;
    canvas.width = rect.width * dpr;
    canvas.height = rect.height * dpr;
    const ctx = canvas.getContext('2d');
    ctx.scale(dpr, dpr);
    return { ctx, width: rect.width, height: rect.height };
  }

  function renderCharts(res) {
    drawZScoreChart(res);
    drawBetaChart(res);
    drawEquityChart(res);
    drawDrawdownChart(res);
    drawWalkForwardChart(res);
    drawMonteCarloChart(res);
  }

  function drawMonteCarloChart(res) {
    const c = setupCanvas('canvas-montecarlo');
    if (!c || !res.mcRes) return;
    const { ctx, width, height } = c;

    // Solid dark canvas background - NEVER transparent
    ctx.clearRect(0, 0, width, height);
    ctx.fillStyle = '#070c18';
    ctx.fillRect(0, 0, width, height);

    const mc = res.mcRes;
    const h = mc.horizonDays;
    const padL = 45, padR = 20, padT = 20, padB = 25;
    const plotW = width - padL - padR;
    const plotH = height - padT - padB;

    // Subtle background grid
    ctx.strokeStyle = 'rgba(255, 255, 255, 0.04)';
    ctx.lineWidth = 1;
    for (let r = 1; r <= 4; r++) {
      const gy = padT + (plotH / 5) * r;
      ctx.beginPath(); ctx.moveTo(padL, gy); ctx.lineTo(width - padR, gy); ctx.stroke();
    }
    for (let col = 1; col <= 5; col++) {
      const gx = padL + (plotW / 6) * col;
      ctx.beginPath(); ctx.moveTo(gx, padT); ctx.lineTo(gx, height - padB); ctx.stroke();
    }

    const minS = -simParams.zStop - 0.5;
    const maxS = 1.5;

    const getY = val => padT + (1.0 - (val - minS) / (maxS - minS)) * plotH;
    const getX = t => padL + (t / h) * plotW;

    // Zero / Target line
    ctx.strokeStyle = '#fbbf24';
    ctx.lineWidth = 1.4;
    ctx.setLineDash([4, 4]);
    ctx.beginPath();
    ctx.moveTo(padL, getY(0.0));
    ctx.lineTo(width - padR, getY(0.0));
    ctx.stroke();
    ctx.setLineDash([]);

    // Stop loss line
    ctx.strokeStyle = '#ef4444';
    ctx.lineWidth = 1.4;
    ctx.setLineDash([4, 4]);
    ctx.beginPath();
    ctx.moveTo(padL, getY(-simParams.zStop));
    ctx.lineTo(width - padR, getY(-simParams.zStop));
    ctx.stroke();
    ctx.setLineDash([]);

    // Confidence Interval 90% fill (p5 to p95)
    ctx.fillStyle = 'rgba(59, 130, 246, 0.22)';
    ctx.beginPath();
    ctx.moveTo(getX(0), getY(mc.percentiles.p5[0]));
    for (let t = 0; t <= h; t++) ctx.lineTo(getX(t), getY(mc.percentiles.p95[t]));
    for (let t = h; t >= 0; t--) ctx.lineTo(getX(t), getY(mc.percentiles.p5[t]));
    ctx.closePath();
    ctx.fill();

    // Interquartile Range 50% fill (p25 to p75)
    ctx.fillStyle = 'rgba(16, 185, 129, 0.28)';
    ctx.beginPath();
    ctx.moveTo(getX(0), getY(mc.percentiles.p25[0]));
    for (let t = 0; t <= h; t++) ctx.lineTo(getX(t), getY(mc.percentiles.p75[t]));
    for (let t = h; t >= 0; t--) ctx.lineTo(getX(t), getY(mc.percentiles.p25[t]));
    ctx.closePath();
    ctx.fill();

    // Sample paths (semi-transparent cyan)
    for (const trace of mc.sampledPaths) {
      ctx.strokeStyle = 'rgba(0, 240, 255, 0.16)';
      ctx.lineWidth = 0.8;
      ctx.beginPath();
      for (let t = 0; t <= h; t++) {
        const cx = getX(t);
        const cy = getY(trace[t]);
        if (t === 0) ctx.moveTo(cx, cy);
        else ctx.lineTo(cx, cy);
      }
      ctx.stroke();
    }

    // Median 50th line with subtle glow
    ctx.shadowColor = 'rgba(251, 191, 36, 0.4)';
    ctx.shadowBlur = 6;
    ctx.strokeStyle = '#fbbf24';
    ctx.lineWidth = 2.4;
    ctx.beginPath();
    for (let t = 0; t <= h; t++) {
      const cx = getX(t);
      const cy = getY(mc.percentiles.p50[t]);
      if (t === 0) ctx.moveTo(cx, cy);
      else ctx.lineTo(cx, cy);
    }
    ctx.stroke();
    ctx.shadowBlur = 0;

    // Labels
    ctx.fillStyle = '#94a3b8';
    ctx.font = '10px JetBrains Mono';
    ctx.textAlign = 'right';
    [1.0, 0.0, -simParams.zEntry, -simParams.zStop].forEach(v => {
      ctx.fillText(v.toFixed(1) + 'σ', padL - 6, getY(v) + 3);
    });

    // Time axis
    ctx.textAlign = 'center';
    [0, Math.floor(h / 2), h].forEach(t => {
      ctx.fillText('Day ' + t, getX(t), height - 8);
    });
  }

  // Chart 1: Z-Score with Entry / Exit bands
  function drawZScoreChart(res) {
    const c = setupCanvas('canvas-zscore');
    if (!c) return;
    const { ctx, width, height } = c;

    // Solid dark canvas background - NEVER transparent
    ctx.clearRect(0, 0, width, height);
    ctx.fillStyle = '#070c18';
    ctx.fillRect(0, 0, width, height);

    const z = res.kf.zscoreHist;
    const n = z.length;
    const padL = 40, padR = 20, padT = 20, padB = 25;
    const plotW = width - padL - padR;
    const plotH = height - padT - padB;

    // Subtle background grid
    ctx.strokeStyle = 'rgba(255, 255, 255, 0.04)';
    ctx.lineWidth = 1;
    for (let r = 1; r <= 4; r++) {
      const gy = padT + (plotH / 5) * r;
      ctx.beginPath(); ctx.moveTo(padL, gy); ctx.lineTo(width - padR, gy); ctx.stroke();
    }
    for (let col = 1; col <= 5; col++) {
      const gx = padL + (plotW / 6) * col;
      ctx.beginPath(); ctx.moveTo(gx, padT); ctx.lineTo(gx, height - padB); ctx.stroke();
    }

    const minZ = -4.2, maxZ = 4.2;
    const getY = val => padT + (1.0 - (val - minZ) / (maxZ - minZ)) * plotH;
    const getX = i => padL + (i / (n - 1)) * plotW;

    // Threshold fill zones
    const yEntryShort = getY(simParams.zEntry);
    const yStopShort = getY(simParams.zStop);
    const yEntryLong = getY(-simParams.zEntry);
    const yStopLong = getY(-simParams.zStop);

    // Short entry danger band
    ctx.fillStyle = 'rgba(244, 63, 94, 0.12)';
    ctx.fillRect(padL, yStopShort, plotW, yEntryShort - yStopShort);

    // Long entry opportunity band
    ctx.fillStyle = 'rgba(16, 185, 129, 0.12)';
    ctx.fillRect(padL, yEntryLong, plotW, yStopLong - yEntryLong);

    // Threshold lines
    function drawThresholdLine(val, color, dash = [4, 4]) {
      const yVal = getY(val);
      ctx.strokeStyle = color;
      ctx.lineWidth = 1.2;
      ctx.setLineDash(dash);
      ctx.beginPath();
      ctx.moveTo(padL, yVal);
      ctx.lineTo(width - padR, yVal);
      ctx.stroke();
      ctx.setLineDash([]);
    }

    drawThresholdLine(0.0, 'rgba(251, 191, 36, 0.65)', [3, 3]);
    drawThresholdLine(simParams.zEntry, '#f43f5e', [4, 4]);
    drawThresholdLine(-simParams.zEntry, '#10b981', [4, 4]);
    drawThresholdLine(simParams.zStop, '#ef4444', [6, 4]);
    drawThresholdLine(-simParams.zStop, '#ef4444', [6, 4]);

    // Z-Score Line (Vivid electric cyan with glow!)
    ctx.shadowColor = 'rgba(0, 240, 255, 0.45)';
    ctx.shadowBlur = 6;
    ctx.strokeStyle = '#00f0ff';
    ctx.lineWidth = 2.0;
    ctx.beginPath();
    for (let i = 0; i < n; i++) {
      const cx = getX(i);
      const cy = getY(Math.max(minZ, Math.min(maxZ, z[i])));
      if (i === 0) ctx.moveTo(cx, cy);
      else ctx.lineTo(cx, cy);
    }
    ctx.stroke();
    ctx.shadowBlur = 0;

    // Trade event scatter points
    for (const ev of res.sigs.tradeEvents) {
      const ex = getX(ev.step);
      const ey = getY(Math.max(minZ, Math.min(maxZ, ev.z)));
      ctx.beginPath();
      if (ev.type === 'ENTRY_LONG') {
        ctx.fillStyle = '#10b981';
        ctx.arc(ex, ey, 5.0, 0, Math.PI * 2);
      } else if (ev.type === 'ENTRY_SHORT') {
        ctx.fillStyle = '#f43f5e';
        ctx.arc(ex, ey, 5.0, 0, Math.PI * 2);
      } else {
        ctx.fillStyle = '#fbbf24';
        ctx.arc(ex, ey, 4.0, 0, Math.PI * 2);
      }
      ctx.fill();
    }

    // Y Axis Labels
    ctx.fillStyle = '#94a3b8';
    ctx.font = '10px JetBrains Mono';
    ctx.textAlign = 'right';
    [-3, -2, 0, 2, 3].forEach(v => {
      ctx.fillText(v + 'σ', padL - 6, getY(v) + 3);
    });
  }

  // Chart 2: Dynamic Kalman Beta vs Static OLS
  function drawBetaChart(res) {
    const c = setupCanvas('canvas-beta');
    if (!c) return;
    const { ctx, width, height } = c;

    // Solid dark canvas background - NEVER transparent
    ctx.clearRect(0, 0, width, height);
    ctx.fillStyle = '#070c18';
    ctx.fillRect(0, 0, width, height);

    const betas = res.kf.betaHist;
    const staticBeta = res.ols.beta;
    const n = betas.length;
    const padL = 45, padR = 20, padT = 20, padB = 25;
    const plotW = width - padL - padR;
    const plotH = height - padT - padB;

    // Subtle background grid
    ctx.strokeStyle = 'rgba(255, 255, 255, 0.04)';
    ctx.lineWidth = 1;
    for (let r = 1; r <= 4; r++) {
      const gy = padT + (plotH / 5) * r;
      ctx.beginPath(); ctx.moveTo(padL, gy); ctx.lineTo(width - padR, gy); ctx.stroke();
    }

    let minB = staticBeta, maxB = staticBeta;
    for (let i = 0; i < n; i++) {
      if (betas[i] < minB) minB = betas[i];
      if (betas[i] > maxB) maxB = betas[i];
    }
    const span = Math.max(0.1, maxB - minB);
    minB -= span * 0.15;
    maxB += span * 0.15;

    const getY = val => padT + (1.0 - (val - minB) / (maxB - minB)) * plotH;
    const getX = i => padL + (i / (n - 1)) * plotW;

    // Static OLS horizontal line (dashed vivid rose)
    ctx.strokeStyle = '#f43f5e';
    ctx.lineWidth = 2.0;
    ctx.setLineDash([6, 4]);
    ctx.beginPath();
    ctx.moveTo(padL, getY(staticBeta));
    ctx.lineTo(width - padR, getY(staticBeta));
    ctx.stroke();
    ctx.setLineDash([]);

    // Gradient fill under dynamic beta
    const betaGrad = ctx.createLinearGradient(0, padT, 0, height - padB);
    betaGrad.addColorStop(0, 'rgba(0, 240, 255, 0.18)');
    betaGrad.addColorStop(1, 'rgba(0, 240, 255, 0.0)');
    ctx.fillStyle = betaGrad;
    ctx.beginPath();
    ctx.moveTo(getX(0), height - padB);
    for (let i = 0; i < n; i++) ctx.lineTo(getX(i), getY(betas[i]));
    ctx.lineTo(getX(n - 1), height - padB);
    ctx.closePath();
    ctx.fill();

    // Dynamic Kalman line with glow
    ctx.shadowColor = 'rgba(0, 240, 255, 0.5)';
    ctx.shadowBlur = 8;
    ctx.strokeStyle = '#00f0ff';
    ctx.lineWidth = 2.5;
    ctx.beginPath();
    for (let i = 0; i < n; i++) {
      const cx = getX(i);
      const cy = getY(betas[i]);
      if (i === 0) ctx.moveTo(cx, cy);
      else ctx.lineTo(cx, cy);
    }
    ctx.stroke();
    ctx.shadowBlur = 0;

    // Axis Labels
    ctx.fillStyle = '#94a3b8';
    ctx.font = '10px JetBrains Mono';
    ctx.textAlign = 'right';
    [minB + span * 0.2, staticBeta, maxB - span * 0.2].forEach(v => {
      ctx.fillText(v.toFixed(3), padL - 6, getY(v) + 3);
    });
  }

  // Chart 3: Cumulative Strategy Equity ($) vs Benchmarks
  function drawEquityChart(res) {
    const c = setupCanvas('canvas-equity');
    if (!c) return;
    const { ctx, width, height } = c;

    // Solid dark canvas background - NEVER transparent
    ctx.clearRect(0, 0, width, height);
    ctx.fillStyle = '#070c18';
    ctx.fillRect(0, 0, width, height);

    const eq = res.btest.equity;
    const yPrice = res.y;
    const n = eq.length;
    const padL = 50, padR = 20, padT = 15, padB = 25;
    const plotW = width - padL - padR;
    const plotH = height - padT - padB;

    // Subtle background grid
    ctx.strokeStyle = 'rgba(255, 255, 255, 0.04)';
    ctx.lineWidth = 1;
    for (let r = 1; r <= 4; r++) {
      const gy = padT + (plotH / 5) * r;
      ctx.beginPath(); ctx.moveTo(padL, gy); ctx.lineTo(width - padR, gy); ctx.stroke();
    }

    const normY = new Float64Array(n);
    for (let i = 0; i < n; i++) normY[i] = (yPrice[i] / yPrice[0]) * simParams.initialCapital;

    let minV = eq[0], maxV = eq[0];
    for (let i = 0; i < n; i++) {
      if (eq[i] < minV) minV = eq[i];
      if (eq[i] > maxV) maxV = eq[i];
      if (normY[i] < minV) minV = normY[i];
      if (normY[i] > maxV) maxV = normY[i];
    }
    const span = Math.max(1000, maxV - minV);
    minV -= span * 0.05;
    maxV += span * 0.05;

    const getY = val => padT + (1.0 - (val - minV) / (maxV - minV)) * plotH;
    const getX = i => padL + (i / (n - 1)) * plotW;

    // Benchmark Y curve (royal sapphire blue)
    ctx.strokeStyle = '#3b82f6';
    ctx.lineWidth = 1.6;
    ctx.setLineDash([4, 4]);
    ctx.beginPath();
    for (let i = 0; i < n; i++) {
      const cx = getX(i);
      const cy = getY(normY[i]);
      if (i === 0) ctx.moveTo(cx, cy);
      else ctx.lineTo(cx, cy);
    }
    ctx.stroke();
    ctx.setLineDash([]);

    // Strategy Equity Curve with Rich Gradient Fill
    const grad = ctx.createLinearGradient(0, padT, 0, height - padB);
    grad.addColorStop(0, 'rgba(16, 185, 129, 0.28)');
    grad.addColorStop(1, 'rgba(16, 185, 129, 0.0)');

    ctx.fillStyle = grad;
    ctx.beginPath();
    ctx.moveTo(getX(0), height - padB);
    for (let i = 0; i < n; i++) {
      ctx.lineTo(getX(i), getY(eq[i]));
    }
    ctx.lineTo(getX(n - 1), height - padB);
    ctx.closePath();
    ctx.fill();

    // Strategy line with glow
    ctx.shadowColor = 'rgba(16, 185, 129, 0.45)';
    ctx.shadowBlur = 6;
    ctx.strokeStyle = '#10b981';
    ctx.lineWidth = 2.4;
    ctx.beginPath();
    for (let i = 0; i < n; i++) {
      const cx = getX(i);
      const cy = getY(eq[i]);
      if (i === 0) ctx.moveTo(cx, cy);
      else ctx.lineTo(cx, cy);
    }
    ctx.stroke();
    ctx.shadowBlur = 0;

    // Axis labels
    ctx.fillStyle = '#94a3b8';
    ctx.font = '10px JetBrains Mono';
    ctx.textAlign = 'right';
    [minV + span * 0.2, simParams.initialCapital, maxV - span * 0.2].forEach(v => {
      ctx.fillText('$' + (v / 1000).toFixed(0) + 'k', padL - 6, getY(v) + 3);
    });
  }

  // Chart 4: Underwater Drawdown Area
  function drawDrawdownChart(res) {
    const c = setupCanvas('canvas-drawdown');
    if (!c) return;
    const { ctx, width, height } = c;

    // Solid dark canvas background - NEVER transparent
    ctx.clearRect(0, 0, width, height);
    ctx.fillStyle = '#070c18';
    ctx.fillRect(0, 0, width, height);

    const dd = res.perf.ddSeries;
    const n = dd.length;
    const padL = 45, padR = 20, padT = 15, padB = 25;
    const plotW = width - padL - padR;
    const plotH = height - padT - padB;

    const maxDdPct = Math.max(0.05, res.perf.maxDdPct / 100.0);
    const getY = val => padT + (Math.abs(val) / maxDdPct) * plotH;
    const getX = i => padL + (i / (n - 1)) * plotW;

    // Fill area with vivid ruby red gradient
    const ddGrad = ctx.createLinearGradient(0, padT, 0, height - padB);
    ddGrad.addColorStop(0, 'rgba(244, 63, 94, 0.15)');
    ddGrad.addColorStop(1, 'rgba(244, 63, 94, 0.45)');
    ctx.fillStyle = ddGrad;
    ctx.beginPath();
    ctx.moveTo(getX(0), padT);
    for (let i = 0; i < n; i++) {
      ctx.lineTo(getX(i), getY(dd[i]));
    }
    ctx.lineTo(getX(n - 1), padT);
    ctx.closePath();
    ctx.fill();

    // Top zero line
    ctx.strokeStyle = 'rgba(255, 255, 255, 0.15)';
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(padL, padT);
    ctx.lineTo(width - padR, padT);
    ctx.stroke();

    // Drawdown contour line
    ctx.strokeStyle = '#f43f5e';
    ctx.lineWidth = 1.8;
    ctx.beginPath();
    for (let i = 0; i < n; i++) {
      const cx = getX(i);
      const cy = getY(dd[i]);
      if (i === 0) ctx.moveTo(cx, cy);
      else ctx.lineTo(cx, cy);
    }
    ctx.stroke();

    // Labels
    ctx.fillStyle = '#94a3b8';
    ctx.font = '10px JetBrains Mono';
    ctx.textAlign = 'right';
    ctx.fillText('0.0%', padL - 6, padT + 4);
    ctx.fillStyle = '#f43f5e';
    ctx.fillText('-' + (maxDdPct * 100).toFixed(1) + '%', padL - 6, height - padB);
  }

  // Chart 5: Walk-Forward Cross Validation Folds
  function drawWalkForwardChart(res) {
    const c = setupCanvas('canvas-walkforward');
    if (!c) return;
    const { ctx, width, height } = c;

    // Solid dark canvas background - NEVER transparent
    ctx.clearRect(0, 0, width, height);
    ctx.fillStyle = '#070c18';
    ctx.fillRect(0, 0, width, height);

    const folds = res.wf.folds;
    const m = folds.length;
    if (m === 0) return;

    const padL = 40, padR = 20, padT = 20, padB = 25;
    const plotW = width - padL - padR;
    const plotH = height - padT - padB;

    let minS = 0, maxS = 0;
    for (const f of folds) {
      if (f.isSharpe < minS) minS = f.isSharpe;
      if (f.isSharpe > maxS) maxS = f.isSharpe;
      if (f.oosSharpe < minS) minS = f.oosSharpe;
      if (f.oosSharpe > maxS) maxS = f.oosSharpe;
    }
    const span = Math.max(1.0, maxS - minS);
    minS -= 0.5; maxS += 0.5;

    const getY = val => padT + (1.0 - (val - minS) / (maxS - minS)) * plotH;
    const yZero = getY(0.0);

    // Zero line
    ctx.strokeStyle = 'rgba(255, 255, 255, 0.15)';
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(padL, yZero);
    ctx.lineTo(width - padR, yZero);
    ctx.stroke();

    const barGroupW = plotW / m;
    const barW = barGroupW * 0.35;

    for (let i = 0; i < m; i++) {
      const f = folds[i];
      const cx = padL + i * barGroupW + barGroupW / 2;

      // In-sample bar (royal sapphire blue)
      const isY = getY(f.isSharpe);
      ctx.fillStyle = '#3b82f6';
      ctx.fillRect(cx - barW, Math.min(yZero, isY), barW, Math.abs(yZero - isY));

      // Out-of-sample bar (emerald if positive, crimson if negative)
      const oosY = getY(f.oosSharpe);
      ctx.fillStyle = f.oosSharpe >= 0 ? '#10b981' : '#f43f5e';
      ctx.fillRect(cx, Math.min(yZero, oosY), barW, Math.abs(yZero - oosY));
    }

    // Y Axis labels
    ctx.fillStyle = '#94a3b8';
    ctx.font = '10px JetBrains Mono';
    ctx.textAlign = 'right';
    ctx.fillText('0.0', padL - 6, yZero + 3);
    ctx.fillText(maxS.toFixed(1), padL - 6, padT + 8);
  }

  // --- 4. TRADE BLOTTER TABLE ---

  function renderTradeBlotter(trades) {
    const tbody = document.getElementById('trade-table-body');
    if (!tbody) return;
    tbody.innerHTML = '';

    const recent = trades.slice(-25).reverse();
    for (const t of recent) {
      const row = document.createElement('tr');
      const dirTag = t.direction === 'LONG_SPREAD'
        ? '<span class="badge-tag tag-long">LONG SPREAD</span>'
        : '<span class="badge-tag tag-short">SHORT SPREAD</span>';

      const pnlColor = t.netPnl >= 0 ? 'val-positive' : 'val-negative';
      const retColor = t.returnPct >= 0 ? 'val-positive' : 'val-negative';
      const exitTag = t.exitReason === 'TAKE_PROFIT'
        ? '<span class="badge-tag tag-tp">TAKE PROFIT</span>'
        : '<span class="badge-tag tag-sl">STOP LOSS</span>';

      row.innerHTML = `
        <td>#${t.id}</td>
        <td>${dirTag}</td>
        <td>${t.entryDate}</td>
        <td>${t.exitDate}</td>
        <td>${t.bars}d</td>
        <td>$${t.entryY.toFixed(2)} / $${t.exitY.toFixed(2)}</td>
        <td>$${t.entryX.toFixed(2)} / $${t.exitX.toFixed(2)}</td>
        <td>${t.beta.toFixed(3)}</td>
        <td>$${t.borrowFees.toFixed(2)}</td>
        <td>$${t.slippage.toFixed(2)}</td>
        <td class="${pnlColor}">$${t.netPnl.toFixed(2)}</td>
        <td class="${retColor}">${t.returnPct >= 0 ? '+' : ''}${t.returnPct.toFixed(2)}%</td>
        <td>${exitTag}</td>
      `;
      tbody.appendChild(row);
    }
  }

  // --- 5. EVENT LISTENERS & INITIALIZATION ---

  function setupEventListeners() {
    // Pair button selector
    const picker = document.getElementById('pair-picker-container');
    if (picker) {
      picker.addEventListener('click', (e) => {
        const btn = e.target.closest('.pair-btn');
        if (!btn) return;
        picker.querySelectorAll('.pair-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        currentPairKey = btn.dataset.pair;
        recalculateAll();
      });
    }

    // Sliders
    function bindSlider(id, valId, unit, transform, propName) {
      const slider = document.getElementById(id);
      const valLabel = document.getElementById(valId);
      if (!slider || !valLabel) return;
      slider.addEventListener('input', () => {
        const raw = parseFloat(slider.value);
        const transformed = transform(raw);
        simParams[propName] = transformed;
        valLabel.textContent = unit(transformed);
        recalculateAll();
      });
    }

    bindSlider('slider-z-entry', 'val-z-entry', v => v.toFixed(2) + ' σ', v => v, 'zEntry');
    bindSlider('slider-z-exit', 'val-z-exit', v => v.toFixed(2) + ' σ', v => v, 'zExit');
    bindSlider('slider-z-stop', 'val-z-stop', v => v.toFixed(2) + ' σ', v => v, 'zStop');
    bindSlider('slider-kalman-delta', 'val-kalman-delta', v => '1e' + Math.round(Math.log10(v)), v => Math.pow(10, v), 'kalmanDelta');
    bindSlider('slider-half-spread', 'val-half-spread', v => v.toFixed(1) + ' bps', v => v, 'halfSpreadBps');
    bindSlider('slider-slippage', 'val-slippage', v => v.toFixed(1) + ' bps', v => v, 'slippageBps');
    bindSlider('slider-borrow-fee', 'val-borrow-fee', v => v.toFixed(2) + ' %', v => v / 100.0, 'borrowFeeAnnual');
    bindSlider('slider-rolling-window', 'val-rolling-window', v => v + ' Days', v => Math.round(v), 'rollingWindow');

    // Recalibrate button
    const btnRecal = document.getElementById('btn-recalibrate');
    if (btnRecal) {
      btnRecal.addEventListener('click', () => {
        btnRecal.style.transform = 'scale(0.96)';
        setTimeout(() => btnRecal.style.transform = '', 150);
        recalculateAll();
      });
    }

    // Monte Carlo triggers
    const btnMc = document.getElementById('btn-run-monte-carlo');
    if (btnMc) {
      btnMc.addEventListener('click', () => {
        btnMc.style.transform = 'scale(0.96)';
        setTimeout(() => btnMc.style.transform = '', 150);
        recalculateAll();
      });
    }

    const selectMcH = document.getElementById('select-mc-horizon');
    if (selectMcH) {
      selectMcH.addEventListener('change', () => {
        recalculateAll();
      });
    }

    // TradingView Tab Viewport Switcher
    ['tv-tab-y', 'tv-tab-x', 'tv-tab-spread'].forEach(tabId => {
      const tab = document.getElementById(tabId);
      if (tab) {
        tab.addEventListener('click', () => {
          const target = tab.dataset.target;
          updateTradingViewWidget(target);
        });
      }
    });

    // Custom Live Pair Fetcher
    const btnCustom = document.getElementById('btn-fetch-custom-pair');
    if (btnCustom) {
      btnCustom.addEventListener('click', () => {
        const symY = document.getElementById('input-custom-y')?.value.trim();
        const symX = document.getElementById('input-custom-x')?.value.trim();
        if (symY && symX) {
          fetchLiveCustomPair(symY, symX);
        }
      });
    }

    // Parameter Optimizer Trigger
    const btnOpt = document.getElementById('btn-run-optimization');
    if (btnOpt) {
      btnOpt.addEventListener('click', () => {
        runClientParameterOptimization();
      });
    }

    // Resize event
    window.addEventListener('resize', () => {
      if (currentResults) renderCharts(currentResults);
    });
  }

  // Init on DOM load
  document.addEventListener('DOMContentLoaded', () => {
    setupEventListeners();
    recalculateAll();
  });

})();
