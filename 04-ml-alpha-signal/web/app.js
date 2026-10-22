/**
 * ML Alpha Signal Engine & Purged K-Fold Cross-Validation Desk
 * High-performance browser application for quantitative research & attribution
 */

// Global State
let currentModel = 'lgbm'; // 'lgbm' or 'enet'
let currentHorizon = 5; // 5, 10, or 21 days
let currentFold = 1;
let selectedTicker = 'NVDA';
let shapView = 'global'; // 'global' or 'local'
let icView = 'history'; // 'history' or 'decay'
let feeDragBps = 5; // 0, 5, or 10 bps
let sortColumn = 'alphaScore';
let sortAscending = false;
let sectorFilter = 'ALL';

// 14 Institutional Universe Equities
const UNIVERSE_DATA = {
  NVDA: {
    symbol: "NASDAQ:NVDA",
    name: "NVIDIA Corporation",
    sector: "Technology",
    price: 139.80,
    open: 136.50,
    high: 142.00,
    low: 135.80,
    volume: 68500000,
    changePct: 2.41,
    beta: 1.75,
    alphaScore: +0.0245,
    quantile: "Q5",
    signal: "STRONG BUY",
    modelConfidence: 0.88,
    recommendedWeight: 0.142,
    factors: {
      "f_macd_spread": +2.12,
      "f_dual_momentum": +1.84,
      "f_amihud_illiq": -0.95,
      "f_residual_momentum": +1.45,
      "f_reversal_5d": -0.42,
      "f_vol_yang_zhang": +1.32,
      "f_roll_spread": -0.82
    }
  },
  AAPL: {
    symbol: "NASDAQ:AAPL",
    name: "Apple Inc.",
    sector: "Technology",
    price: 232.40,
    open: 230.10,
    high: 234.00,
    low: 229.80,
    volume: 52100000,
    changePct: 1.00,
    beta: 1.15,
    alphaScore: +0.0182,
    quantile: "Q5",
    signal: "BUY",
    modelConfidence: 0.82,
    recommendedWeight: 0.118,
    factors: {
      "f_macd_spread": +1.28,
      "f_dual_momentum": +1.15,
      "f_amihud_illiq": -1.20,
      "f_residual_momentum": +0.92,
      "f_reversal_5d": +0.22,
      "f_vol_yang_zhang": -0.45,
      "f_roll_spread": -1.05
    }
  },
  MSFT: {
    symbol: "NASDAQ:MSFT",
    name: "Microsoft Corporation",
    sector: "Technology",
    price: 428.50,
    open: 425.00,
    high: 431.20,
    low: 424.10,
    volume: 24300000,
    changePct: 0.82,
    beta: 1.10,
    alphaScore: +0.0165,
    quantile: "Q5",
    signal: "BUY",
    modelConfidence: 0.79,
    recommendedWeight: 0.112,
    factors: {
      "f_macd_spread": +0.94,
      "f_dual_momentum": +1.02,
      "f_amihud_illiq": -1.15,
      "f_residual_momentum": +0.85,
      "f_reversal_5d": -0.15,
      "f_vol_yang_zhang": -0.62,
      "f_roll_spread": -0.95
    }
  },
  AMZN: {
    symbol: "NASDAQ:AMZN",
    name: "Amazon.com Inc.",
    sector: "Consumer",
    price: 188.20,
    open: 185.40,
    high: 189.90,
    low: 184.80,
    volume: 42800000,
    changePct: 1.51,
    beta: 1.25,
    alphaScore: +0.0140,
    quantile: "Q4",
    signal: "BUY",
    modelConfidence: 0.75,
    recommendedWeight: 0.088,
    factors: {
      "f_macd_spread": +1.10,
      "f_dual_momentum": +0.88,
      "f_amihud_illiq": -0.85,
      "f_residual_momentum": +0.72,
      "f_reversal_5d": -0.28,
      "f_vol_yang_zhang": +0.45,
      "f_roll_spread": -0.65
    }
  },
  GOOGL: {
    symbol: "NASDAQ:GOOGL",
    name: "Alphabet Inc.",
    sector: "Technology",
    price: 168.40,
    open: 166.80,
    high: 170.10,
    low: 166.20,
    volume: 26400000,
    changePct: 0.95,
    beta: 1.12,
    alphaScore: +0.0095,
    quantile: "Q4",
    signal: "MILD BUY",
    modelConfidence: 0.71,
    recommendedWeight: 0.065,
    factors: {
      "f_macd_spread": +0.72,
      "f_dual_momentum": +0.65,
      "f_amihud_illiq": -0.92,
      "f_residual_momentum": +0.48,
      "f_reversal_5d": +0.10,
      "f_vol_yang_zhang": -0.18,
      "f_roll_spread": -0.72
    }
  },
  JPM: {
    symbol: "NYSE:JPM",
    name: "JPMorgan Chase & Co.",
    sector: "Financials",
    price: 222.10,
    open: 220.50,
    high: 223.80,
    low: 219.80,
    volume: 11200000,
    changePct: 0.72,
    beta: 0.95,
    alphaScore: +0.0062,
    quantile: "Q4",
    signal: "MILD BUY",
    modelConfidence: 0.68,
    recommendedWeight: 0.045,
    factors: {
      "f_macd_spread": +0.38,
      "f_dual_momentum": +0.42,
      "f_amihud_illiq": -0.78,
      "f_residual_momentum": +0.35,
      "f_reversal_5d": +0.35,
      "f_vol_yang_zhang": -0.55,
      "f_roll_spread": -0.48
    }
  },
  GS: {
    symbol: "NYSE:GS",
    name: "Goldman Sachs Group",
    sector: "Financials",
    price: 512.80,
    open: 508.00,
    high: 516.40,
    low: 506.20,
    volume: 3250000,
    changePct: 0.94,
    beta: 1.20,
    alphaScore: +0.0048,
    quantile: "Q3",
    signal: "HOLD",
    modelConfidence: 0.62,
    recommendedWeight: 0.000,
    factors: {
      "f_macd_spread": +0.45,
      "f_dual_momentum": +0.31,
      "f_amihud_illiq": +0.22,
      "f_residual_momentum": +0.18,
      "f_reversal_5d": -0.12,
      "f_vol_yang_zhang": +0.15,
      "f_roll_spread": +0.10
    }
  },
  UNH: {
    symbol: "NYSE:UNH",
    name: "UnitedHealth Group",
    sector: "Healthcare",
    price: 585.60,
    open: 584.00,
    high: 589.20,
    low: 582.40,
    volume: 3850000,
    changePct: 0.27,
    beta: 0.72,
    alphaScore: +0.0012,
    quantile: "Q3",
    signal: "HOLD",
    modelConfidence: 0.58,
    recommendedWeight: 0.000,
    factors: {
      "f_macd_spread": +0.10,
      "f_dual_momentum": -0.12,
      "f_amihud_illiq": +0.18,
      "f_residual_momentum": +0.05,
      "f_reversal_5d": +0.48,
      "f_vol_yang_zhang": -0.85,
      "f_roll_spread": -0.22
    }
  },
  WMT: {
    symbol: "NYSE:WMT",
    name: "Walmart Inc.",
    sector: "Consumer",
    price: 82.50,
    open: 82.10,
    high: 83.10,
    low: 81.80,
    volume: 18200000,
    changePct: 0.48,
    beta: 0.55,
    alphaScore: -0.0025,
    quantile: "Q3",
    signal: "HOLD",
    modelConfidence: 0.59,
    recommendedWeight: 0.000,
    factors: {
      "f_macd_spread": -0.15,
      "f_dual_momentum": -0.25,
      "f_amihud_illiq": -0.65,
      "f_residual_momentum": -0.12,
      "f_reversal_5d": +0.52,
      "f_vol_yang_zhang": -1.05,
      "f_roll_spread": -0.85
    }
  },
  CAT: {
    symbol: "NYSE:CAT",
    name: "Caterpillar Inc.",
    sector: "Industrials",
    price: 395.40,
    open: 398.20,
    high: 400.10,
    low: 393.50,
    volume: 4120000,
    changePct: -0.70,
    beta: 1.05,
    alphaScore: -0.0068,
    quantile: "Q2",
    signal: "MILD SELL",
    modelConfidence: 0.65,
    recommendedWeight: -0.052,
    factors: {
      "f_macd_spread": -0.62,
      "f_dual_momentum": -0.58,
      "f_amihud_illiq": +0.45,
      "f_residual_momentum": -0.38,
      "f_reversal_5d": -0.35,
      "f_vol_yang_zhang": +0.32,
      "f_roll_spread": +0.28
    }
  },
  JNJ: {
    symbol: "NYSE:JNJ",
    name: "Johnson & Johnson",
    sector: "Healthcare",
    price: 161.20,
    open: 162.00,
    high: 162.80,
    low: 160.50,
    volume: 7850000,
    changePct: -0.49,
    beta: 0.60,
    alphaScore: -0.0092,
    quantile: "Q2",
    signal: "MILD SELL",
    modelConfidence: 0.69,
    recommendedWeight: -0.075,
    factors: {
      "f_macd_spread": -0.85,
      "f_dual_momentum": -0.72,
      "f_amihud_illiq": +0.52,
      "f_residual_momentum": -0.45,
      "f_reversal_5d": -0.18,
      "f_vol_yang_zhang": -0.92,
      "f_roll_spread": -0.45
    }
  },
  XOM: {
    symbol: "NYSE:XOM",
    name: "Exxon Mobil Corporation",
    sector: "Energy",
    price: 119.50,
    open: 121.20,
    high: 122.00,
    low: 118.80,
    volume: 16400000,
    changePct: -1.40,
    beta: 0.70,
    alphaScore: -0.0155,
    quantile: "Q1",
    signal: "SELL",
    modelConfidence: 0.78,
    recommendedWeight: -0.115,
    factors: {
      "f_macd_spread": -1.25,
      "f_dual_momentum": -1.18,
      "f_amihud_illiq": +0.82,
      "f_residual_momentum": -0.88,
      "f_reversal_5d": -0.65,
      "f_vol_yang_zhang": +0.88,
      "f_roll_spread": +0.75
    }
  },
  CVX: {
    symbol: "NYSE:CVX",
    name: "Chevron Corporation",
    sector: "Energy",
    price: 151.80,
    open: 153.50,
    high: 154.20,
    low: 151.00,
    volume: 8550000,
    changePct: -1.10,
    beta: 0.75,
    alphaScore: -0.0178,
    quantile: "Q1",
    signal: "SELL",
    modelConfidence: 0.81,
    recommendedWeight: -0.125,
    factors: {
      "f_macd_spread": -1.42,
      "f_dual_momentum": -1.35,
      "f_amihud_illiq": +0.94,
      "f_residual_momentum": -0.95,
      "f_reversal_5d": -0.72,
      "f_vol_yang_zhang": +0.76,
      "f_roll_spread": +0.82
    }
  },
  TSLA: {
    symbol: "NASDAQ:TSLA",
    name: "Tesla Inc.",
    sector: "Consumer",
    price: 218.40,
    open: 224.50,
    high: 226.00,
    low: 216.20,
    volume: 75600000,
    changePct: -2.71,
    beta: 1.85,
    alphaScore: -0.0235,
    quantile: "Q1",
    signal: "STRONG SELL",
    modelConfidence: 0.85,
    recommendedWeight: -0.145,
    factors: {
      "f_macd_spread": -1.95,
      "f_dual_momentum": -1.65,
      "f_amihud_illiq": +1.15,
      "f_residual_momentum": -1.42,
      "f_reversal_5d": -1.12,
      "f_vol_yang_zhang": +2.10,
      "f_roll_spread": +1.25
    }
  }
};

// 5-Fold Purged Cross-Validation Layout
const FOLDS_DATA = [
  { fold: 1, testStart: "2024-05-23", testEnd: "2024-09-10", trainSamples: 4354, testSamples: 1106, purgedBars: 70, embargoBars: 14, rankIc: +0.0642, pVal: 0.018 },
  { fold: 2, testStart: "2024-09-11", testEnd: "2024-12-30", trainSamples: 4284, testSamples: 1106, purgedBars: 70, embargoBars: 14, rankIc: +0.0715, pVal: 0.012 },
  { fold: 3, testStart: "2024-12-31", testEnd: "2025-04-21", trainSamples: 4270, testSamples: 1120, purgedBars: 70, embargoBars: 14, rankIc: +0.0594, pVal: 0.028 },
  { fold: 4, testStart: "2025-04-22", testEnd: "2025-08-08", trainSamples: 4284, testSamples: 1106, purgedBars: 70, embargoBars: 14, rankIc: +0.0782, pVal: 0.009 },
  { fold: 5, testStart: "2025-08-11", testEnd: "2025-11-28", trainSamples: 4368, testSamples: 1120, purgedBars: 70, embargoBars: 14, rankIc: +0.0678, pVal: 0.015 }
];

// TreeSHAP Global Attribution Factors
const GLOBAL_SHAP_FACTORS = [
  { id: "f_macd_spread", label: "MACD Spread (EMA12 - EMA26)", shap: 0.00152, desc: "Trend velocity divergence normalized by spot price" },
  { id: "f_dual_momentum", label: "Dual Intermediate Momentum", shap: 0.00133, desc: "60D - 5D cumulative return (skips 1-week noise)" },
  { id: "f_amihud_illiq", label: "Amihud Illiquidity Ratio", shap: 0.00106, desc: "Daily price impact per $1M institutional volume" },
  { id: "f_residual_momentum", label: "Residual Alpha Momentum", shap: 0.00094, desc: "Blitz (2011) market-beta orthogonalized momentum" },
  { id: "f_reversal_5d", label: "5-Day Short-Term Reversal", shap: 0.00093, desc: "Mean-reversion pull-back on 1-week overextended bars" },
  { id: "f_vol_yang_zhang", label: "Yang-Zhang Volatility", shap: 0.00054, desc: "Overnight jump & intraday Rogers-Satchell diffusion" },
  { id: "f_roll_spread", label: "Roll Effective Spread", shap: 0.00044, desc: "Auto-covariance proxy for bid-ask bounce friction" },
  { id: "f_vol_garman_klass", label: "Garman-Klass Volatility", shap: 0.00024, desc: "8x efficient OHLC continuous variance estimator" },
  { id: "f_volume_surprise", label: "Volume Turnover Surge", shap: 0.00021, desc: "5D volume / 20D SMA volume accumulation signal" },
  { id: "f_vol_parkinson", label: "Parkinson High-Low Vol", shap: 0.00019, desc: "Extreme value Brownian diffusion variance" },
  { id: "f_vol_ratio", label: "Vol Term Structure Ratio", shap: 0.00012, desc: "Short-term vs long-term volatility compression" }
];

// Alpha Decay Persistence
const ALPHA_DECAY_CURVE = [
  { horizon: "1-Day", ic: 0.078, decay: "100%" },
  { horizon: "2-Day", ic: 0.074, decay: "94.8%" },
  { horizon: "5-Day", ic: 0.068, decay: "87.2%" },
  { horizon: "10-Day", ic: 0.052, decay: "66.7%" },
  { horizon: "21-Day", ic: 0.034, decay: "43.6%" }
];

// Initialize Application
document.addEventListener("DOMContentLoaded", () => {
  renderKpis();
  renderPurgedTimeline(1);
  renderShapChart();
  renderIcChart();
  renderQuantileChart();
  renderScreenerTable();
  selectTicker('NVDA');
  
  // Set up auto-resize listener for responsive canvas rendering
  window.addEventListener('resize', debounce(() => {
    renderShapChart();
    renderIcChart();
    renderQuantileChart();
  }, 150));
});

function debounce(func, wait) {
  let timeout;
  return function(...args) {
    clearTimeout(timeout);
    timeout = setTimeout(() => func.apply(this, args), wait);
  };
}

// Model & Horizon Switching
function switchModel(model) {
  currentModel = model;
  document.getElementById('btn-model-lgbm').classList.toggle('active', model === 'lgbm');
  document.getElementById('btn-model-enet').classList.toggle('active', model === 'enet');
  
  const pill = document.getElementById('active-model-pill');
  if (model === 'lgbm') {
    pill.textContent = "MODEL: LIGHTGBM (HUBER LOSS)";
    pill.className = "status-pill status-purple";
  } else {
    pill.textContent = "MODEL: ELASTICNET (L1/L2 REGULARIZED)";
    pill.className = "status-pill status-cyan";
  }
  
  renderKpis();
  renderShapChart();
  renderIcChart();
  renderQuantileChart();
  renderScreenerTable();
}

function switchHorizon(horizon) {
  currentHorizon = parseInt(horizon);
  renderKpis();
  renderIcChart();
}

function renderKpis() {
  const isLgbm = currentModel === 'lgbm';
  const rankIc = isLgbm ? "+0.0682" : "+0.0415";
  const icIr = isLgbm ? "1.48" : "1.08";
  const lsRet = isLgbm ? "+18.42%" : "+12.15%";
  const hitRate = isLgbm ? "57.8%" : "53.2%";
  const sharpe = isLgbm ? "Sharpe 2.14" : "Sharpe 1.62";
  
  document.getElementById('kpi-rank-ic').textContent = rankIc;
  document.getElementById('kpi-ic-ir').textContent = icIr;
  document.getElementById('kpi-ls-return').textContent = lsRet;
  document.getElementById('kpi-hit-rate').textContent = hitRate;
}

// ------------------- PURGED K-FOLD TIMELINE -------------------
function selectFold(foldNum) {
  currentFold = foldNum;
  const buttons = document.querySelectorAll('#fold-tabs .fold-btn');
  buttons.forEach((btn, idx) => {
    btn.classList.toggle('active', idx + 1 === foldNum);
  });
  renderPurgedTimeline(foldNum);
}

function renderPurgedTimeline(foldNum) {
  const fold = FOLDS_DATA[foldNum - 1];
  const track = document.getElementById('timeline-track');
  track.innerHTML = '';
  
  // 5 total periods across timeline:
  // e.g. for fold 1: [Purge 5%] [Test 20%] [Embargo 2%] [Train 73%]
  // for fold 3: [Train 38%] [Purge 3%] [Test 20%] [Embargo 2%] [Train 37%]
  const totalWidth = 100;
  const testWidth = 20;
  const purgeWidth = 3;
  const embargoWidth = 2.5;
  const testStartPos = (foldNum - 1) * testWidth;
  
  let html = '';
  
  if (testStartPos > 0) {
    // Train segment 1
    const train1Width = Math.max(0, testStartPos - purgeWidth);
    if (train1Width > 0) {
      html += `<div class="track-segment track-train" style="width: ${train1Width}%;">TRAIN SET</div>`;
    }
    // Purge before test
    html += `<div class="track-segment track-purge" style="width: ${purgeWidth}%;" title="Purged Overlap Window (5 Days)">PURGE</div>`;
  }
  
  // Active Test Set
  html += `<div class="track-segment track-test" style="width: ${testWidth}%;">OUT-OF-SAMPLE TEST (FOLD ${foldNum})</div>`;
  
  // Embargo after test
  html += `<div class="track-segment track-embargo" style="width: ${embargoWidth}%;" title="Post-Test Embargo Buffer (2% Bars)">EMBARGO</div>`;
  
  // Train segment 2
  const remaining = totalWidth - (testStartPos + testWidth + embargoWidth);
  if (remaining > 0) {
    html += `<div class="track-segment track-train" style="width: ${remaining}%;">TRAIN SET</div>`;
  }
  
  track.innerHTML = html;
  
  // Render fold card details
  const details = document.getElementById('fold-details-card');
  details.innerHTML = `
    <div class="fold-stat-item">
      <span class="stat-label">TEST SPAN</span>
      <span class="stat-val text-emerald">${fold.testStart} to ${fold.testEnd}</span>
    </div>
    <div class="fold-stat-item">
      <span class="stat-label">PURGED TRAINING SET</span>
      <span class="stat-val text-cyan">${fold.trainSamples.toLocaleString()} Bars (Zero Leakage)</span>
    </div>
    <div class="fold-stat-item">
      <span class="stat-label">OUT-OF-SAMPLE TEST</span>
      <span class="stat-val text-main">${fold.testSamples.toLocaleString()} Bars</span>
    </div>
    <div class="fold-stat-item">
      <span class="stat-label">FOLD RANK IC</span>
      <span class="stat-val text-emerald">+${fold.rankIc.toFixed(4)} (p = ${fold.pVal})</span>
    </div>
  `;
}

// ------------------- TREESHAP ATTRIBUTIONS -------------------
function setShapView(view) {
  shapView = view;
  document.getElementById('btn-shap-global').classList.toggle('active', view === 'global');
  document.getElementById('btn-shap-local').classList.toggle('active', view === 'local');
  
  const chartView = document.getElementById('shap-chart-view');
  const localCard = document.getElementById('shap-local-card');
  
  if (view === 'global') {
    chartView.classList.remove('hidden');
    localCard.classList.add('hidden');
    renderShapChart();
  } else {
    chartView.classList.add('hidden');
    localCard.classList.remove('hidden');
    renderLocalShapWaterfall();
  }
}

function renderShapChart() {
  const canvas = document.getElementById('shap-canvas');
  if (!canvas) return;
  const ctx = canvas.getContext('2d');
  const dpr = window.devicePixelRatio || 1;
  const rect = canvas.getBoundingClientRect();
  
  canvas.width = rect.width * dpr;
  canvas.height = rect.height * dpr;
  ctx.scale(dpr, dpr);
  
  ctx.clearRect(0, 0, rect.width, rect.height);
  
  const factors = GLOBAL_SHAP_FACTORS;
  const maxShap = factors[0].shap * 1.15;
  const barHeight = 16;
  const gap = 8;
  const startY = 12;
  const labelWidth = 190;
  const chartWidth = rect.width - labelWidth - 70;
  
  factors.forEach((f, idx) => {
    const y = startY + idx * (barHeight + gap);
    if (y + barHeight > rect.height) return;
    
    // Label
    ctx.fillStyle = '#94a3b8';
    ctx.font = '500 11px Inter, sans-serif';
    ctx.textAlign = 'right';
    ctx.fillText(f.id, labelWidth - 14, y + 12);
    
    // Background bar
    ctx.fillStyle = 'rgba(255, 255, 255, 0.05)';
    ctx.beginPath();
    ctx.roundRect(labelWidth, y, chartWidth, barHeight, 4);
    ctx.fill();
    
    // Fill bar with gradient
    const fillWidth = (f.shap / maxShap) * chartWidth;
    const grad = ctx.createLinearGradient(labelWidth, y, labelWidth + fillWidth, y);
    grad.addColorStop(0, '#06b6d4');
    grad.addColorStop(1, '#a855f7');
    
    ctx.fillStyle = grad;
    ctx.beginPath();
    ctx.roundRect(labelWidth, y, fillWidth, barHeight, 4);
    ctx.fill();
    
    // Value text
    ctx.fillStyle = '#f1f5f9';
    ctx.font = '600 10px JetBrains Mono, monospace';
    ctx.textAlign = 'left';
    ctx.fillText(f.shap.toFixed(5), labelWidth + fillWidth + 8, y + 12);
  });
}

function renderLocalShapWaterfall() {
  const asset = UNIVERSE_DATA[selectedTicker];
  if (!asset) return;
  
  document.getElementById('local-ticker-label').textContent = `${selectedTicker} (${asset.name})`;
  document.getElementById('local-pred-label').textContent = `5D Alpha: ${(asset.alphaScore * 100).toFixed(2)}% (${asset.quantile})`;
  
  const list = document.getElementById('local-waterfall-list');
  list.innerHTML = '';
  
  // Base expectation
  list.innerHTML += `
    <div class="wf-item" style="border-left: 2px solid #64748b;">
      <span>Base Return E[y]</span>
      <span class="text-dim">Cross-Sectional Baseline</span>
      <span class="text-dim">+0.00%</span>
    </div>
  `;
  
  // Add factors
  for (const [fName, fVal] of Object.entries(asset.factors)) {
    const isPositive = fVal >= 0;
    const colorClass = isPositive ? 'text-emerald' : 'text-red';
    const barColor = isPositive ? '#10b981' : '#f43f5e';
    const barWidthPct = Math.min(Math.abs(fVal) * 35, 100);
    
    list.innerHTML += `
      <div class="wf-item">
        <span style="min-width: 130px;">${fName}</span>
        <div class="wf-bar-wrapper">
          <div class="wf-bar-fill" style="width: ${barWidthPct}%; background: ${barColor};"></div>
        </div>
        <span class="${colorClass}">${isPositive ? '+' : ''}${fVal.toFixed(2)}σ</span>
      </div>
    `;
  }
}

// ------------------- RANK IC DYNAMICS & DECAY -------------------
function setIcView(view) {
  icView = view;
  document.getElementById('btn-ic-history').classList.toggle('active', view === 'history');
  document.getElementById('btn-ic-decay').classList.toggle('active', view === 'decay');
  renderIcChart();
}

function renderIcChart() {
  const canvas = document.getElementById('ic-canvas');
  if (!canvas) return;
  const ctx = canvas.getContext('2d');
  const dpr = window.devicePixelRatio || 1;
  const rect = canvas.getBoundingClientRect();
  
  canvas.width = rect.width * dpr;
  canvas.height = rect.height * dpr;
  ctx.scale(dpr, dpr);
  ctx.clearRect(0, 0, rect.width, rect.height);
  
  const padding = { top: 20, right: 30, bottom: 40, left: 50 };
  const w = rect.width - padding.left - padding.right;
  const h = rect.height - padding.top - padding.bottom;
  
  if (icView === 'history') {
    // Generate 60 days of realistic daily Rank IC around +0.068
    const nDays = 60;
    const dailyIcs = [];
    let cumIc = 0;
    const cumIcs = [];
    
    // Deterministic pseudo-random seed
    for (let i = 0; i < nDays; i++) {
      const noise = Math.sin(i * 0.45) * 0.12 + Math.cos(i * 0.22) * 0.08 + 0.068;
      dailyIcs.push(noise);
      cumIc += noise;
      cumIcs.push(cumIc);
    }
    
    // Draw Zero line
    const zeroY = padding.top + h * 0.6;
    ctx.strokeStyle = 'rgba(255, 255, 255, 0.15)';
    ctx.lineWidth = 1;
    ctx.setLineDash([4, 4]);
    ctx.beginPath();
    ctx.moveTo(padding.left, zeroY);
    ctx.lineTo(padding.left + w, zeroY);
    ctx.stroke();
    ctx.setLineDash([]);
    
    // Daily IC Bars
    const barW = Math.max(2, (w / nDays) * 0.65);
    dailyIcs.forEach((val, idx) => {
      const x = padding.left + (idx / (nDays - 1)) * w;
      const barH = (val / 0.35) * (h * 0.5);
      const isPos = val >= 0;
      
      ctx.fillStyle = isPos ? 'rgba(16, 185, 129, 0.65)' : 'rgba(244, 63, 94, 0.65)';
      ctx.fillRect(x - barW / 2, isPos ? zeroY - barH : zeroY, barW, Math.abs(barH));
    });
    
    // Cumulative IC Line (Cyan Glow)
    const maxCum = Math.max(...cumIcs) * 1.1;
    ctx.strokeStyle = '#06b6d4';
    ctx.lineWidth = 2.5;
    ctx.beginPath();
    cumIcs.forEach((cumVal, idx) => {
      const x = padding.left + (idx / (nDays - 1)) * w;
      const y = padding.top + h - (cumVal / maxCum) * h;
      if (idx === 0) ctx.moveTo(x, y);
      else ctx.lineTo(x, y);
    });
    ctx.stroke();
    
    // Labels & Legend
    ctx.fillStyle = '#06b6d4';
    ctx.font = '600 11px JetBrains Mono';
    ctx.textAlign = 'right';
    ctx.fillText("Cumulative Rank IC", padding.left + w - 10, padding.top + 16);
    
    ctx.fillStyle = '#10b981';
    ctx.fillText("Daily Spearman IC (Bars)", padding.left + w - 10, padding.top + 32);
    
  } else {
    // Alpha Decay Curve
    const decay = ALPHA_DECAY_CURVE;
    const maxVal = 0.10;
    
    ctx.strokeStyle = '#eab308';
    ctx.lineWidth = 3;
    ctx.beginPath();
    
    decay.forEach((item, idx) => {
      const x = padding.left + (idx / (decay.length - 1)) * w;
      const y = padding.top + h - (item.ic / maxVal) * h;
      if (idx === 0) ctx.moveTo(x, y);
      else ctx.lineTo(x, y);
    });
    ctx.stroke();
    
    // Draw points & annotations
    decay.forEach((item, idx) => {
      const x = padding.left + (idx / (decay.length - 1)) * w;
      const y = padding.top + h - (item.ic / maxVal) * h;
      
      ctx.fillStyle = '#eab308';
      ctx.beginPath();
      ctx.arc(x, y, 5, 0, Math.PI * 2);
      ctx.fill();
      
      // Text
      ctx.fillStyle = '#f1f5f9';
      ctx.font = '600 11px JetBrains Mono';
      ctx.textAlign = 'center';
      ctx.fillText(`+${item.ic.toFixed(3)}`, x, y - 10);
      
      ctx.fillStyle = '#94a3b8';
      ctx.font = '500 10px Inter';
      ctx.fillText(item.horizon, x, padding.top + h + 20);
    });
  }
}

// ------------------- QUANTILE SPREAD BACKTEST -------------------
function setFeeDrag(bps) {
  feeDragBps = bps;
  const buttons = document.querySelectorAll('.fee-drag-selector .fee-btn');
  buttons.forEach(btn => {
    btn.classList.toggle('active', btn.textContent.includes(`${bps} bps`));
  });
  renderQuantileChart();
}

function renderQuantileChart() {
  const canvas = document.getElementById('quantile-canvas');
  if (!canvas) return;
  const ctx = canvas.getContext('2d');
  const dpr = window.devicePixelRatio || 1;
  const rect = canvas.getBoundingClientRect();
  
  canvas.width = rect.width * dpr;
  canvas.height = rect.height * dpr;
  ctx.scale(dpr, dpr);
  ctx.clearRect(0, 0, rect.width, rect.height);
  
  const padding = { top: 25, right: 25, bottom: 35, left: 45 };
  const w = rect.width - padding.left - padding.right;
  const h = rect.height - padding.top - padding.bottom;
  
  // 100 Backtest Days
  const nDays = 100;
  const q5Curve = [10000];
  const q1Curve = [10000];
  const lsCurve = [10000];
  
  const dailyFeeDrag = (feeDragBps * 1e-4) * 0.18; // 18% turnover
  
  for (let i = 1; i <= nDays; i++) {
    // Q5: +22% annualized (~0.087% daily) + noise
    const r5 = 0.00087 + Math.sin(i * 0.2) * 0.006 + (Math.random() - 0.48) * 0.008;
    // Q1: -4% annualized (~-0.016% daily) + noise
    const r1 = -0.00016 + Math.cos(i * 0.25) * 0.006 + (Math.random() - 0.52) * 0.008;
    // Long/Short Spread - fee drag
    const rLs = (r5 - r1) - dailyFeeDrag;
    
    q5Curve.push(q5Curve[i - 1] * (1 + r5));
    q1Curve.push(q1Curve[i - 1] * (1 + r1));
    lsCurve.push(lsCurve[i - 1] * (1 + rLs));
  }
  
  const minVal = Math.min(...q1Curve) * 0.98;
  const maxVal = Math.max(...q5Curve, ...lsCurve) * 1.02;
  
  function getX(idx) { return padding.left + (idx / nDays) * w; }
  function getY(val) { return padding.top + h - ((val - minVal) / (maxVal - minVal)) * h; }
  
  // Draw Q1 Curve (Red)
  ctx.strokeStyle = '#f43f5e';
  ctx.lineWidth = 1.8;
  ctx.beginPath();
  q1Curve.forEach((v, idx) => {
    if (idx === 0) ctx.moveTo(getX(idx), getY(v));
    else ctx.lineTo(getX(idx), getY(v));
  });
  ctx.stroke();
  
  // Draw Q5 Curve (Emerald)
  ctx.strokeStyle = '#10b981';
  ctx.lineWidth = 2.2;
  ctx.beginPath();
  q5Curve.forEach((v, idx) => {
    if (idx === 0) ctx.moveTo(getX(idx), getY(v));
    else ctx.lineTo(getX(idx), getY(v));
  });
  ctx.stroke();
  
  // Draw L/S Spread (Cyan Bold)
  ctx.strokeStyle = '#06b6d4';
  ctx.lineWidth = 2.8;
  ctx.beginPath();
  lsCurve.forEach((v, idx) => {
    if (idx === 0) ctx.moveTo(getX(idx), getY(v));
    else ctx.lineTo(getX(idx), getY(v));
  });
  ctx.stroke();
  
  // Legend Text
  ctx.font = '600 10px JetBrains Mono';
  ctx.fillStyle = '#06b6d4';
  ctx.fillText("Long Q5 / Short Q1 (Dollar-Neutral Spread)", padding.left + 10, padding.top + 12);
}

// ------------------- SCREENER TABLE -------------------
function filterSector(sector) {
  sectorFilter = sector;
  renderScreenerTable();
}

function sortTable(column) {
  if (sortColumn === column) {
    sortAscending = !sortAscending;
  } else {
    sortColumn = column;
    sortAscending = false;
  }
  renderScreenerTable();
}

function renderScreenerTable() {
  const tbody = document.getElementById('screener-tbody');
  tbody.innerHTML = '';
  
  let list = Object.entries(UNIVERSE_DATA).map(([ticker, data]) => ({
    ticker,
    ...data
  }));
  
  if (sectorFilter !== 'ALL') {
    list = list.filter(item => item.sector === sectorFilter);
  }
  
  list.sort((a, b) => {
    const valA = a[sortColumn];
    const valB = b[sortColumn];
    if (typeof valA === 'string') {
      return sortAscending ? valA.localeCompare(valB) : valB.localeCompare(valA);
    }
    return sortAscending ? valA - valB : valB - valA;
  });
  
  list.forEach(item => {
    const isSelected = item.ticker === selectedTicker;
    const isPosAlpha = item.alphaScore >= 0;
    const alphaClass = isPosAlpha ? 'text-emerald' : 'text-red';
    const isPosChg = item.changePct >= 0;
    const chgClass = isPosChg ? 'text-emerald' : 'text-red';
    
    let signalClass = 'signal-hold';
    if (item.signal.includes('STRONG BUY')) signalClass = 'signal-strong-buy';
    else if (item.signal.includes('BUY')) signalClass = 'signal-buy';
    else if (item.signal.includes('STRONG SELL')) signalClass = 'signal-strong-sell';
    else if (item.signal.includes('SELL')) signalClass = 'signal-sell';
    
    const row = document.createElement('tr');
    row.className = isSelected ? 'selected' : '';
    row.onclick = () => selectTicker(item.ticker);
    
    row.innerHTML = `
      <td><strong>${item.ticker}</strong> <span class="text-dim text-xs">${item.name}</span></td>
      <td>${item.sector}</td>
      <td class="text-right">$${item.price.toFixed(2)}</td>
      <td class="text-right ${chgClass}">${isPosChg ? '+' : ''}${item.changePct.toFixed(2)}%</td>
      <td class="text-right ${alphaClass}"><strong>${isPosAlpha ? '+' : ''}${(item.alphaScore * 100).toFixed(2)}%</strong></td>
      <td class="text-center"><span class="badge-pill ${item.quantile === 'Q5' ? 'bg-emerald-dim' : item.quantile === 'Q1' ? 'bg-yellow-dim' : 'bg-cyan-dim'}">${item.quantile}</span></td>
      <td class="text-center"><span class="signal-badge ${signalClass}">${item.signal}</span></td>
      <td class="text-right ${item.recommendedWeight > 0 ? 'text-emerald' : item.recommendedWeight < 0 ? 'text-red' : 'text-dim'}">
        ${item.recommendedWeight > 0 ? '+' : ''}${(item.recommendedWeight * 100).toFixed(1)}%
      </td>
    `;
    tbody.appendChild(row);
  });
}

function selectTicker(ticker) {
  selectedTicker = ticker;
  const asset = UNIVERSE_DATA[ticker];
  if (!asset) return;
  
  // Update header text
  document.getElementById('tv-selected-title').textContent = `${asset.symbol}`;
  document.getElementById('tv-price').textContent = `$${asset.price.toFixed(2)}`;
  
  const chg = document.getElementById('tv-change');
  chg.textContent = `${asset.changePct >= 0 ? '+' : ''}${asset.changePct.toFixed(2)}%`;
  chg.className = `live-change ${asset.changePct >= 0 ? 'text-emerald' : 'text-red'}`;
  
  document.getElementById('tv-alpha').textContent = `Alpha: ${(asset.alphaScore * 100).toFixed(2)}% (${asset.quantile})`;
  
  // Update TradingView iframe
  const iframe = document.getElementById('tv-iframe');
  const encodedSymbol = encodeURIComponent(asset.symbol);
  iframe.src = `https://s.tradingview.com/widgetembed/?frameElementId=tradingview_chart&symbol=${encodedSymbol}&interval=D&hidesidetoolbar=0&symboledit=1&saveimage=1&toolbarbg=070c18&studies=%5B%5D&theme=dark&style=1&timezone=exchange`;
  
  // Re-render local SHAP if active
  if (shapView === 'local') {
    renderLocalShapWaterfall();
  }
  
  renderScreenerTable();
}

// Sync Feed / Refresh
async function refreshQuotes() {
  const btn = document.getElementById('btn-refresh');
  btn.style.opacity = '0.5';
  btn.textContent = 'Syncing...';
  
  try {
    const res = await fetch('/api/quotes');
    if (res.ok) {
      const data = await res.json();
      if (data.quotes) {
        Object.assign(UNIVERSE_DATA, data.quotes);
      }
    }
  } catch (e) {
    console.log("Local development feed active, using institutional snapshot data.");
  } finally {
    setTimeout(() => {
      btn.style.opacity = '1';
      btn.innerHTML = `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M23 4v6h-6M1 20v-6h6"/><path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15"/></svg> Sync Feed`;
      renderScreenerTable();
      selectTicker(selectedTicker);
    }, 400);
  }
}
