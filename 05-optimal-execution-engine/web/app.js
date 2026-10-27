/**
 * Almgren-Chriss Optimal Execution Engine & Institutional TCA Desk
 * Client-Side First-Principles Mathematics & Real-Time Visualization
 */

// Global Chart references
let trajectoryChart = null;
let slicesChart = null;
let frontierChart = null;
let simulationChart = null;

// Presets configuration
const PRESETS = {
  sp500_block: {
    shares: 100000,
    price: 150.00,
    horizon: 60,
    intervals: 30,
    riskLog: -5.0,  // 1e-5
    vol: 0.20,
    impactModel: "linear"
  },
  illiquid_tech: {
    shares: 50000,
    price: 85.00,
    horizon: 120,
    intervals: 30,
    riskLog: -4.0,  // 1e-4
    vol: 0.45,
    impactModel: "squareroot"
  },
  crisis_spike: {
    shares: 150000,
    price: 210.00,
    horizon: 30,
    intervals: 30,
    riskLog: -3.0,  // 1e-3 Urgent
    vol: 0.65,
    impactModel: "adaptive"
  },
  vwap_glider: {
    shares: 80000,
    price: 120.00,
    horizon: 390,
    intervals: 60,
    riskLog: -7.5,  // ~3e-8 Passive
    vol: 0.25,
    impactModel: "obizhaeva"
  }
};

// Microstructure Constants
const IMPACT_PARAMS = {
  gamma: 2.5e-7,  // Permanent impact $/share per share
  eta: 2.5e-6,    // Temporary impact $/share per unit trading rate
  rho: 0.05,      // Obizhaeva-Wang order book resilience
  gamma_0: 4.0e-6
};

// Initialize Application on DOM Ready
document.addEventListener("DOMContentLoaded", () => {
  setupEventListeners();
  initCharts();
  recalculateAll();
  runStochasticSimulation();
});

// Setup UI Listeners
function setupEventListeners() {
  const sharesInput = document.getElementById("sharesInput");
  const priceInput = document.getElementById("priceInput");
  const horizonSelect = document.getElementById("horizonSelect");
  const intervalsSelect = document.getElementById("intervalsSelect");
  const riskSlider = document.getElementById("riskSlider");
  const volSlider = document.getElementById("volSlider");
  const impactModelSelect = document.getElementById("impactModelSelect");

  const updateNotional = () => {
    const s = parseFloat(sharesInput.value) || 0;
    const p = parseFloat(priceInput.value) || 0;
    const notional = s * p;
    document.getElementById("notionalDisplay").textContent = "$" + notional.toLocaleString(undefined, {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2
    });
    recalculateAll();
  };

  sharesInput.addEventListener("input", updateNotional);
  priceInput.addEventListener("input", updateNotional);
  horizonSelect.addEventListener("change", recalculateAll);
  intervalsSelect.addEventListener("change", recalculateAll);
  impactModelSelect.addEventListener("change", recalculateAll);

  riskSlider.addEventListener("input", (e) => {
    const logVal = parseFloat(e.target.value);
    const lam = Math.pow(10, logVal);
    document.getElementById("riskAversionVal").textContent = lam.toExponential(1);
    recalculateAll();
  });

  volSlider.addEventListener("input", (e) => {
    const v = parseFloat(e.target.value);
    document.getElementById("volVal").textContent = Math.round(v * 100) + "%";
    recalculateAll();
  });

  // Scenario buttons
  document.querySelectorAll(".btn-scenario").forEach(btn => {
    btn.addEventListener("click", (e) => {
      document.querySelectorAll(".btn-scenario").forEach(b => b.classList.remove("active"));
      btn.classList.add("active");
      const presetKey = btn.dataset.preset;
      applyPreset(presetKey);
    });
  });

  // Action buttons
  document.getElementById("btnSimulate").addEventListener("click", () => {
    runStochasticSimulation();
  });

  document.getElementById("btnReset").addEventListener("click", () => {
    applyPreset("sp500_block");
  });
}

function applyPreset(key) {
  const p = PRESETS[key];
  if (!p) return;

  document.getElementById("sharesInput").value = p.shares;
  document.getElementById("priceInput").value = p.price;
  document.getElementById("horizonSelect").value = p.horizon;
  document.getElementById("intervalsSelect").value = p.intervals;
  document.getElementById("riskSlider").value = p.riskLog;
  document.getElementById("volSlider").value = p.vol;
  document.getElementById("impactModelSelect").value = p.impactModel;

  const lam = Math.pow(10, p.riskLog);
  document.getElementById("riskAversionVal").textContent = lam.toExponential(1);
  document.getElementById("volVal").textContent = Math.round(p.vol * 100) + "%";

  const notional = p.shares * p.price;
  document.getElementById("notionalDisplay").textContent = "$" + notional.toLocaleString(undefined, {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  });

  recalculateAll();
  runStochasticSimulation();
}

// Get Current Config
function getConfig() {
  const X = parseFloat(document.getElementById("sharesInput").value) || 100000;
  const S0 = parseFloat(document.getElementById("priceInput").value) || 150.0;
  const T_mins = parseFloat(document.getElementById("horizonSelect").value) || 60;
  const N = parseInt(document.getElementById("intervalsSelect").value) || 30;
  const riskLog = parseFloat(document.getElementById("riskSlider").value) || -5;
  const lambda = Math.pow(10, riskLog);
  const annualVol = parseFloat(document.getElementById("volSlider").value) || 0.30;
  const impactModel = document.getElementById("impactModelSelect").value;

  const T_sec = T_mins * 60;
  const tau = T_sec / N;
  const tradingSecondsPerYear = 252 * 6.5 * 3600;
  const sigma_sec = S0 * (annualVol / Math.sqrt(tradingSecondsPerYear));

  return {
    X, S0, T_mins, T_sec, N, tau, lambda, annualVol, sigma_sec, impactModel
  };
}

// Mathematical Models
function calculateKappa(lambda, sigma_sec, tau, eta) {
  if (lambda <= 1e-12) return 0.0;
  const arg = 1.0 + 0.5 * (lambda * (sigma_sec ** 2) * (tau ** 2)) / Math.max(1e-12, eta);
  // arccosh(x) = ln(x + sqrt(x^2 - 1))
  const arccoshVal = Math.log(arg + Math.sqrt(Math.max(0, arg * arg - 1)));
  return arccoshVal / tau;
}

function calculateAlmgrenChrissTrajectory(cfg, customLambda = null) {
  const lam = (customLambda !== null) ? customLambda : cfg.lambda;
  const kappa = calculateKappa(lam, cfg.sigma_sec, cfg.tau, IMPACT_PARAMS.eta);
  const trajectory = [];
  const times = [];

  for (let j = 0; j <= cfg.N; j++) {
    const t_j = j * cfg.tau;
    times.push(j);

    if (kappa <= 1e-12) {
      trajectory.push(cfg.X * (1.0 - t_j / cfg.T_sec));
    } else {
      const kappa_T = kappa * cfg.T_sec;
      if (kappa_T > 700) {
        trajectory.push(j === 0 ? cfg.X : 0.0);
      } else {
        const num = Math.sinh(kappa * (cfg.T_sec - t_j));
        const den = Math.sinh(kappa_T);
        trajectory.push(den === 0 ? 0.0 : Math.max(0, cfg.X * (num / den)));
      }
    }
  }
  trajectory[0] = cfg.X;
  trajectory[cfg.N] = 0.0;
  return { times, trajectory, kappa };
}

function calculateTWAPTrajectory(cfg) {
  const trajectory = [];
  for (let j = 0; j <= cfg.N; j++) {
    trajectory.push(cfg.X * (1.0 - j / cfg.N));
  }
  return trajectory;
}

function calculateVWAPTrajectory(cfg) {
  // U-curve volume distribution
  const weights = [];
  let sumW = 0;
  for (let k = 0; k < cfg.N; k++) {
    const x = -1.0 + 2.0 * (k / (cfg.N - 1 || 1));
    const w = 0.5 * (x * x) + 0.3; // parabolic curve
    weights.push(w);
    sumW += w;
  }
  const normW = weights.map(w => w / sumW);
  const trajectory = [cfg.X];
  let rem = cfg.X;
  for (let k = 0; k < cfg.N; k++) {
    rem = Math.max(0, rem - cfg.X * normW[k]);
    trajectory.push(rem);
  }
  trajectory[cfg.N] = 0.0;
  return { trajectory, normW };
}

function calculateObizhaevaWangTrajectory(cfg) {
  const rho = IMPACT_PARAMS.rho;
  const denom = 2.0 + rho * cfg.T_sec;
  const n_init = cfg.X / denom;
  const continuousRate = (rho * cfg.X) / denom;

  const trajectory = [cfg.X];
  for (let j = 1; j < cfg.N; j++) {
    const t_elapsed = j * cfg.tau;
    const rem = Math.max(0, (cfg.X - n_init) - continuousRate * t_elapsed);
    trajectory.push(rem);
  }
  trajectory.push(0.0);
  return trajectory;
}

// Compute Expected Cost & Variance
function computeExpectedCost(trades, cfg) {
  const gamma = IMPACT_PARAMS.gamma;
  const eta = IMPACT_PARAMS.eta;
  const perm = 0.5 * gamma * (cfg.X ** 2);
  let temp = 0;
  for (let k = 0; k < trades.length; k++) {
    temp += eta * (trades[k] ** 2) / cfg.tau;
  }
  return { total: perm + temp, perm, temp };
}

function computeCostVariance(trajectory, cfg) {
  let sumSq = 0;
  for (let j = 1; j < trajectory.length; j++) {
    sumSq += (trajectory[j] ** 2);
  }
  return (cfg.sigma_sec ** 2) * cfg.tau * sumSq;
}

// Initialize Charts
function initCharts() {
  const commonOptions = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        labels: {
          color: '#94a3b8',
          font: { family: 'JetBrains Mono', size: 10 }
        }
      },
      tooltip: {
        backgroundColor: '#0c1322',
        borderColor: '#334155',
        borderWidth: 1,
        titleColor: '#00f0ff',
        bodyColor: '#f8fafc',
        titleFont: { family: 'JetBrains Mono' },
        bodyFont: { family: 'JetBrains Mono' }
      }
    },
    scales: {
      x: {
        grid: { color: 'rgba(30, 41, 59, 0.4)' },
        ticks: { color: '#64748b', font: { family: 'JetBrains Mono', size: 10 } }
      },
      y: {
        grid: { color: 'rgba(30, 41, 59, 0.4)' },
        ticks: { color: '#64748b', font: { family: 'JetBrains Mono', size: 10 } }
      }
    }
  };

  // 1. Trajectory Chart
  const ctxTraj = document.getElementById("trajectoryChart").getContext("2d");
  trajectoryChart = new Chart(ctxTraj, {
    type: 'line',
    data: {
      labels: [],
      datasets: [
        {
          label: 'Almgren-Chriss (Active λ)',
          borderColor: '#00f0ff',
          backgroundColor: 'rgba(0, 240, 255, 0.1)',
          borderWidth: 2.5,
          tension: 0.1,
          pointRadius: 0,
          data: []
        },
        {
          label: 'TWAP Benchmark',
          borderColor: '#94a3b8',
          borderDash: [5, 5],
          borderWidth: 1.5,
          pointRadius: 0,
          data: []
        },
        {
          label: 'VWAP Benchmark',
          borderColor: '#a855f7',
          borderWidth: 1.5,
          pointRadius: 0,
          data: []
        },
        {
          label: 'Obizhaeva-Wang Resilience',
          borderColor: '#fbbf24',
          borderDash: [3, 3],
          borderWidth: 1.5,
          pointRadius: 0,
          data: []
        }
      ]
    },
    options: {
      ...commonOptions,
      scales: {
        ...commonOptions.scales,
        x: { ...commonOptions.scales.x, title: { display: true, text: 'Interval Step (k)', color: '#64748b' } },
        y: { ...commonOptions.scales.y, title: { display: true, text: 'Holdings (Shares)', color: '#64748b' } }
      }
    }
  });

  // 2. Child Order Slices Chart
  const ctxSlices = document.getElementById("slicesChart").getContext("2d");
  slicesChart = new Chart(ctxSlices, {
    type: 'bar',
    data: {
      labels: [],
      datasets: [
        {
          label: 'Almgren-Chriss Slice Size',
          backgroundColor: 'rgba(0, 240, 255, 0.7)',
          hoverBackgroundColor: '#00f0ff',
          borderRadius: 3,
          data: []
        },
        {
          label: 'VWAP Slice Size',
          backgroundColor: 'rgba(168, 85, 247, 0.4)',
          borderRadius: 3,
          data: []
        }
      ]
    },
    options: {
      ...commonOptions,
      scales: {
        ...commonOptions.scales,
        x: { ...commonOptions.scales.x, title: { display: true, text: 'Interval (k)', color: '#64748b' } },
        y: { ...commonOptions.scales.y, title: { display: true, text: 'Shares Liquidated', color: '#64748b' } }
      }
    }
  });

  // 3. Frontier Chart
  const ctxFrontier = document.getElementById("frontierChart").getContext("2d");
  frontierChart = new Chart(ctxFrontier, {
    type: 'scatter',
    data: {
      datasets: [
        {
          label: 'Almgren-Chriss Frontier',
          borderColor: '#10b981',
          backgroundColor: 'rgba(16, 185, 129, 0.2)',
          showLine: true,
          pointRadius: 0,
          borderWidth: 2,
          data: []
        },
        {
          label: 'Active Operating Point',
          backgroundColor: '#00f0ff',
          borderColor: '#ffffff',
          pointRadius: 7,
          pointHoverRadius: 9,
          data: []
        }
      ]
    },
    options: {
      ...commonOptions,
      scales: {
        ...commonOptions.scales,
        x: { ...commonOptions.scales.x, title: { display: true, text: 'Timing Risk Std Dev ($)', color: '#64748b' } },
        y: { ...commonOptions.scales.y, title: { display: true, text: 'Expected Impact Cost ($)', color: '#64748b' } }
      }
    }
  });

  // 4. Stochastic Price & Fills Simulation Chart
  const ctxSim = document.getElementById("simulationChart").getContext("2d");
  simulationChart = new Chart(ctxSim, {
    type: 'line',
    data: {
      labels: [],
      datasets: [
        {
          label: 'Simulated Mid-Price ($)',
          borderColor: '#f8fafc',
          borderWidth: 1.5,
          pointRadius: 0,
          data: []
        },
        {
          label: 'Executed Fill Price ($)',
          borderColor: '#f43f5e',
          backgroundColor: 'rgba(244, 63, 94, 0.8)',
          pointRadius: 4,
          pointHoverRadius: 6,
          showLine: false,
          data: []
        },
        {
          label: 'Arrival Price Benchmark',
          borderColor: '#94a3b8',
          borderDash: [6, 4],
          borderWidth: 1,
          pointRadius: 0,
          data: []
        }
      ]
    },
    options: {
      ...commonOptions,
      scales: {
        ...commonOptions.scales,
        x: { ...commonOptions.scales.x, title: { display: true, text: 'Step (k)', color: '#64748b' } },
        y: { ...commonOptions.scales.y, title: { display: true, text: 'Asset Price ($)', color: '#64748b' } }
      }
    }
  });
}

// Master Recalculation Routine
function recalculateAll() {
  const cfg = getConfig();

  // 1. Calculate Trajectories
  const ac = calculateAlmgrenChrissTrajectory(cfg);
  const twapTraj = calculateTWAPTrajectory(cfg);
  const vwap = calculateVWAPTrajectory(cfg);
  const owTraj = calculateObizhaevaWangTrajectory(cfg);

  // Compute trade slices: n_k = x_{k-1} - x_k
  const acTrades = [];
  const vwapTrades = [];
  const twapTrades = [];
  for (let k = 0; k < cfg.N; k++) {
    acTrades.push(ac.trajectory[k] - ac.trajectory[k + 1]);
    vwapTrades.push(vwap.trajectory[k] - vwap.trajectory[k + 1]);
    twapTrades.push(twapTraj[k] - twapTraj[k + 1]);
  }

  // 2. Compute Costs & Variance for Active Config
  const costAC = computeExpectedCost(acTrades, cfg);
  const varAC = computeCostVariance(ac.trajectory, cfg);
  const stdAC = Math.sqrt(Math.max(0, varAC));

  const costTWAP = computeExpectedCost(twapTrades, cfg);
  const stdTWAP = Math.sqrt(computeCostVariance(twapTraj, cfg));

  const costVWAP = computeExpectedCost(vwapTrades, cfg);
  const stdVWAP = Math.sqrt(computeCostVariance(vwap.trajectory, cfg));

  // Update KPI Cards
  const notional = cfg.X * cfg.S0;
  const shortfallBps = (costAC.total / notional) * 10000;
  const avgFillPrice = cfg.S0 - (costAC.total / cfg.X);

  document.getElementById("kpiShortfallUsd").textContent = "$" + costAC.total.toLocaleString(undefined, {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  });
  document.getElementById("kpiShortfallBps").textContent = shortfallBps.toFixed(2) + " bps slippage";
  document.getElementById("kpiAvgFill").textContent = "$" + avgFillPrice.toFixed(3);
  document.getElementById("kpiRiskStd").textContent = "$" + stdAC.toLocaleString(undefined, {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  });
  document.getElementById("kpiUrgencyKappa").textContent = "κ = " + ac.kappa.toFixed(5) + " s⁻¹";

  const permPct = Math.round((costAC.perm / Math.max(1e-6, costAC.total)) * 100);
  const tempPct = 100 - permPct;
  document.getElementById("kpiImpactSplit").textContent = permPct + "% / " + tempPct + "%";

  // 3. Update Trajectory Chart
  const labels = Array.from({ length: cfg.N + 1 }, (_, i) => i);
  trajectoryChart.data.labels = labels;
  trajectoryChart.data.datasets[0].data = ac.trajectory;
  trajectoryChart.data.datasets[1].data = twapTraj;
  trajectoryChart.data.datasets[2].data = vwap.trajectory;
  trajectoryChart.data.datasets[3].data = owTraj;
  trajectoryChart.update();

  // 4. Update Slices Chart
  const sliceLabels = Array.from({ length: cfg.N }, (_, i) => i);
  slicesChart.data.labels = sliceLabels;
  slicesChart.data.datasets[0].data = acTrades;
  slicesChart.data.datasets[1].data = vwapTrades;
  slicesChart.update();

  // 5. Update Efficient Frontier Curve
  const frontierPoints = [];
  for (let logL = -8; logL <= -2; logL += 0.25) {
    const l = Math.pow(10, logL);
    const testTraj = calculateAlmgrenChrissTrajectory(cfg, l);
    const testTrades = [];
    for (let k = 0; k < cfg.N; k++) {
      testTrades.push(testTraj.trajectory[k] - testTraj.trajectory[k + 1]);
    }
    const c = computeExpectedCost(testTrades, cfg);
    const s = Math.sqrt(computeCostVariance(testTraj.trajectory, cfg));
    frontierPoints.push({ x: s, y: c.total });
  }

  frontierChart.data.datasets[0].data = frontierPoints;
  frontierChart.data.datasets[1].data = [{ x: stdAC, y: costAC.total }];
  frontierChart.update();

  // 6. Update TCA Comparison Table
  renderTCATable([
    {
      name: "Almgren-Chriss (Active λ=" + cfg.lambda.toExponential(1) + ")",
      fill: avgFillPrice,
      shortfall: costAC.total,
      slippageBps: shortfallBps,
      perm: costAC.perm,
      temp: costAC.temp,
      std: stdAC,
      isOptimal: true
    },
    {
      name: "TWAP Benchmark (Linear)",
      fill: cfg.S0 - (costTWAP.total / cfg.X),
      shortfall: costTWAP.total,
      slippageBps: (costTWAP.total / notional) * 10000,
      perm: costTWAP.perm,
      temp: costTWAP.temp,
      std: stdTWAP,
      isOptimal: false
    },
    {
      name: "VWAP Benchmark (U-Curve)",
      fill: cfg.S0 - (costVWAP.total / cfg.X),
      shortfall: costVWAP.total,
      slippageBps: (costVWAP.total / notional) * 10000,
      perm: costVWAP.perm,
      temp: costVWAP.temp,
      std: stdVWAP,
      isOptimal: false
    }
  ]);
}

// Render TCA Attribution Table
function renderTCATable(rows) {
  const tbody = document.getElementById("tcaTableBody");
  tbody.innerHTML = "";

  rows.forEach(r => {
    const tr = document.createElement("tr");
    tr.innerHTML = `
      <td class="${r.isOptimal ? 'strong cyan' : ''}">${r.name}</td>
      <td class="strong">$${r.fill.toFixed(3)}</td>
      <td class="${r.isOptimal ? 'cyan' : ''}">$${r.shortfall.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</td>
      <td>${r.slippageBps.toFixed(2)} bps</td>
      <td>$${r.perm.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</td>
      <td>$${r.temp.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</td>
      <td class="emerald">$${r.std.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</td>
      <td><span class="${r.isOptimal ? 'status-badge-opt' : 'status-badge-bench'}">${r.isOptimal ? 'OPTIMAL' : 'BENCH'}</span></td>
    `;
    tbody.appendChild(tr);
  });
}

// Stochastic Execution Simulator
function runStochasticSimulation() {
  const cfg = getConfig();
  const ac = calculateAlmgrenChrissTrajectory(cfg);
  const trades = [];
  for (let k = 0; k < cfg.N; k++) {
    trades.push(ac.trajectory[k] - ac.trajectory[k + 1]);
  }

  const prices = [cfg.S0];
  const fills = [];
  const arrivalArr = Array.from({ length: cfg.N + 1 }, () => cfg.S0);

  let curPrice = cfg.S0;
  for (let k = 0; k < cfg.N; k++) {
    const n_k = trades[k];
    const v_k = n_k / cfg.tau;

    // Temporary impact penalty on child order
    const tempPenalty = IMPACT_PARAMS.eta * v_k;
    const execPrice = curPrice - tempPenalty;
    fills.push({ x: k, y: execPrice });

    // Permanent impact shift
    const permDrop = IMPACT_PARAMS.gamma * v_k * cfg.tau;

    // Random Brownian motion step: normal(0, 1) * sigma * sqrt(tau)
    const u1 = Math.random();
    const u2 = Math.random();
    const z0 = Math.sqrt(-2.0 * Math.log(Math.max(1e-12, u1))) * Math.cos(2.0 * Math.PI * u2);
    const dW = z0 * Math.sqrt(cfg.tau);

    curPrice = Math.max(1.0, curPrice - permDrop + cfg.sigma_sec * dW);
    prices.push(curPrice);
  }

  // Update simulation chart
  simulationChart.data.labels = Array.from({ length: cfg.N + 1 }, (_, i) => i);
  simulationChart.data.datasets[0].data = prices;
  simulationChart.data.datasets[1].data = fills;
  simulationChart.data.datasets[2].data = arrivalArr;
  simulationChart.update();

  const simBadge = document.getElementById("simStatusBadge");
  simBadge.textContent = "SIMULATION COMPLETE";
  simBadge.style.color = "#10b981";
  simBadge.style.borderColor = "rgba(16, 185, 129, 0.4)";
}
