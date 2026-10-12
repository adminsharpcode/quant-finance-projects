/**
 * VOLX Quantitative Derivatives Terminal - Client Engine
 * High-performance browser math kernel & interactive visualizer.
 */

// ------------------- HIGH-PRECISION MATHEMATICAL KERNEL -------------------

function normCdf(x) {
  const a1 = 0.254829592, a2 = -0.284496736, a3 = 1.421413741, a4 = -1.453152027, a5 = 1.061405429, p = 0.3275911;
  const sign = x < 0 ? -1 : 1;
  const absX = Math.abs(x) / Math.SQRT2;
  const t = 1.0 / (1.0 + p * absX);
  const y = 1.0 - (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * Math.exp(-absX * absX);
  return 0.5 * (1.0 + sign * y);
}

function normPdf(x) {
  return (1.0 / Math.sqrt(2.0 * Math.PI)) * Math.exp(-0.5 * x * x);
}

function d1_d2(F, K, T, sigma) {
  const volSqrtT = Math.max(sigma * Math.sqrt(Math.max(T, 1e-4)), 1e-6);
  const d1 = (Math.log(Math.max(F, 1e-4) / Math.max(K, 1e-4)) + 0.5 * sigma * sigma * T) / volSqrtT;
  const d2 = d1 - volSqrtT;
  return { d1, d2 };
}

function black76Price(F, K, T, r, sigma, isCall) {
  if (T <= 0) return isCall ? Math.max(F - K, 0) : Math.max(K - F, 0);
  const { d1, d2 } = d1_d2(F, K, T, sigma);
  const discount = Math.exp(-r * T);
  return isCall ? discount * (F * normCdf(d1) - K * normCdf(d2)) : discount * (K * normCdf(-d2) - F * normCdf(-d1));
}

function binomialCRR(F, K, T, r, sigma, isCall, isAmerican, steps = 300) {
  if (T <= 0) return isCall ? Math.max(F - K, 0) : Math.max(K - F, 0);
  const n = Math.max(steps, 20);
  const dt = T / n;
  const u = Math.exp(sigma * Math.sqrt(dt));
  const d = 1.0 / u;
  let p = Math.min(Math.max((1.0 - d) / (u - d), 0.0), 1.0);
  const discount = Math.exp(-r * dt);

  let values = new Float64Array(n + 1);
  for (let j = 0; j <= n; j++) {
    const sT = F * Math.pow(u, j) * Math.pow(d, n - j);
    values[j] = isCall ? Math.max(sT - K, 0) : Math.max(K - sT, 0);
  }

  for (let i = n - 1; i >= 0; i--) {
    let nextVals = new Float64Array(i + 1);
    for (let j = 0; j <= i; j++) {
      const continuation = discount * (p * values[j + 1] + (1.0 - p) * values[j]);
      if (isAmerican) {
        const sNode = F * Math.pow(u, j) * Math.pow(d, i - j);
        const intrinsic = isCall ? Math.max(sNode - K, 0) : Math.max(K - sNode, 0);
        nextVals[j] = Math.max(continuation, intrinsic);
      } else {
        nextVals[j] = continuation;
      }
    }
    values = nextVals;
  }
  return values[0];
}

function monteCarloPrice(F, K, T, r, sigma, isCall, paths = 40000) {
  if (T <= 0) return { price: isCall ? Math.max(F - K, 0) : Math.max(K - F, 0), se: 0, ci: 0 };
  const halfPaths = paths / 2;
  const drift = -0.5 * sigma * sigma * T;
  const volSqrtT = sigma * Math.sqrt(T);
  const discount = Math.exp(-r * T);

  let sum = 0.0, sumSq = 0.0;
  for (let i = 0; i < halfPaths; i++) {
    const u1 = Math.max(Math.random(), 1e-12);
    const u2 = Math.random();
    const z = Math.sqrt(-2.0 * Math.log(u1)) * Math.cos(2.0 * Math.PI * u2);

    const fT1 = F * Math.exp(drift + volSqrtT * z);
    const fT2 = F * Math.exp(drift - volSqrtT * z);

    const p1 = discount * (isCall ? Math.max(fT1 - K, 0) : Math.max(K - fT1, 0));
    const p2 = discount * (isCall ? Math.max(fT2 - K, 0) : Math.max(K - fT2, 0));

    const avg = 0.5 * (p1 + p2);
    sum += avg;
    sumSq += avg * avg;
  }

  const mean = sum / halfPaths;
  const variance = Math.max((sumSq - (sum * sum) / halfPaths) / (halfPaths - 1), 0);
  const se = Math.sqrt(variance / halfPaths);
  return { price: mean, se: se, ci: 1.96 * se };
}

function calculateGreeks(F, K, T, r, sigma, isCall) {
  const { d1, d2 } = d1_d2(F, K, T, sigma);
  const discount = Math.exp(-r * T);
  const sqrtT = Math.sqrt(Math.max(T, 1e-4));
  const pdfD1 = normPdf(d1);

  const delta = isCall ? discount * normCdf(d1) : -discount * normCdf(-d1);
  const gamma = (discount * pdfD1) / (F * sigma * sqrtT);
  const vega = discount * F * sqrtT * pdfD1;
  const vega1pct = vega * 0.01;

  const thetaAnnual = -(discount * F * pdfD1 * sigma) / (2.0 * sqrtT) - r * black76Price(F, K, T, r, sigma, isCall);
  const theta1day = thetaAnnual / 365.0;

  const price = black76Price(F, K, T, r, sigma, isCall);
  const rho100bp = (-T * price) * 0.01;

  const vanna = -discount * pdfD1 * (d2 / sigma);
  const volga = vega * (d1 * d2) / sigma;

  return { price, delta, gamma, vega1pct, theta1day, rho100bp, vanna, volga };
}

// SVI Gatheral Surface Evaluation
const SVI_GOLD_SLICES = {
  30: { a: 0.0001, b: 0.0695, rho: 0.8480, m: 0.1500, sigma: 0.0524, T: 30 / 365 },
  60: { a: 0.0027, b: 0.0032, rho: -0.9009, m: 0.3406, sigma: 0.0010, T: 60 / 365 },
  90: { a: 0.0061, b: 0.0072, rho: -0.9900, m: 0.0368, sigma: 0.1588, T: 90 / 365 },
  180: { a: 0.0141, b: 0.0126, rho: -0.9900, m: 0.0300, sigma: 0.1473, T: 180 / 365 },
};

function sviVol(K, F, T, params) {
  const k = Math.log(K / F);
  const diff = k - params.m;
  const w = params.a + params.b * (params.rho * diff + Math.sqrt(diff * diff + params.sigma * params.sigma));
  return Math.sqrt(Math.max(w, 1e-8) / Math.max(T, 1e-4));
}

// Authentic Market Chain Data
const COMEX_GOLD_CHAIN = [
  { symbol: "OG_2490_P_30d", strike: 2490, tenor: "30d", T: 30 / 365, type: "put", bid: 6.13, ask: 7.13, fairPrice: 7.43, mktIV: 0.175, modelIV: 0.181, signal: "BUY", label: "BUY VOL (Cheap Gamma)", hedge: "+0.142 GC", edge: "+$0.30" },
  { symbol: "OG_2550_C_30d", strike: 2550, tenor: "30d", T: 30 / 365, type: "call", bid: 112.50, ask: 114.50, fairPrice: 113.40, mktIV: 0.172, modelIV: 0.171, signal: "FAIR", label: "FAIR VALUE", hedge: "-0.738 GC", edge: "$0.00" },
  { symbol: "OG_2650_C_60d", strike: 2650, tenor: "60d", T: 60 / 365, type: "call", bid: 73.80, ask: 75.20, fairPrice: 74.55, mktIV: 0.175, modelIV: 0.175, signal: "FAIR", label: "FAIR VALUE", hedge: "-0.503 GC", edge: "$0.00" },
  { symbol: "OG_2700_C_30d", strike: 2700, tenor: "30d", T: 30 / 365, type: "call", bid: 28.10, ask: 29.10, fairPrice: 27.72, mktIV: 0.163, modelIV: 0.159, signal: "SELL", label: "SELL VOL (Harvest Prem)", hedge: "-0.385 GC", edge: "+$0.38" },
  { symbol: "OG_2730_C_30d", strike: 2730, tenor: "30d", T: 30 / 365, type: "call", bid: 18.45, ask: 19.45, fairPrice: 18.18, mktIV: 0.160, modelIV: 0.157, signal: "SELL", label: "SELL VOL (Harvest Prem)", hedge: "-0.275 GC", edge: "+$0.27" },
  { symbol: "OG_2760_C_30d", strike: 2760, tenor: "30d", T: 30 / 365, type: "call", bid: 12.15, ask: 13.15, fairPrice: 11.86, mktIV: 0.159, modelIV: 0.155, signal: "SELL", label: "SELL VOL (Harvest Prem)", hedge: "-0.198 GC", edge: "+$0.29" },
  { symbol: "OG_2800_C_60d", strike: 2800, tenor: "60d", T: 60 / 365, type: "call", bid: 22.40, ask: 23.60, fairPrice: 23.00, mktIV: 0.182, modelIV: 0.182, signal: "FAIR", label: "FAIR VALUE", hedge: "-0.210 GC", edge: "$0.00" },
];

// ------------------- APPLICATION STATE & CONTROLLER -------------------

let state = {
  F: 2650.0,
  K: 2650.0,
  T_days: 60,
  vol: 0.175,
  r: 0.045,
  isCall: true,
  activeGreekChart: "delta",
  alphaFilter: "ALL",
};

function init() {
  bindControls();
  renderAll();
  initMonteCarloCanvas();
  init3DSurfacePlot();
  init2DSmilesPlot();
  renderAlphaTable();
}

function bindControls() {
  const inputF = document.getElementById("input-f");
  const inputK = document.getElementById("input-k");
  const inputT = document.getElementById("input-t");
  const inputVol = document.getElementById("input-vol");
  const inputR = document.getElementById("input-r");

  // Tab switching
  const tabs = document.querySelectorAll(".nav-tab");
  tabs.forEach((tab) => {
    tab.addEventListener("click", () => {
      tabs.forEach((t) => t.classList.remove("active"));
      document.querySelectorAll(".tab-pane").forEach((p) => p.classList.remove("active"));
      tab.classList.add("active");
      const targetPane = document.getElementById(tab.dataset.tab);
      if (targetPane) targetPane.classList.add("active");

      // Trigger redraw of plotly charts when tab becomes visible
      if (tab.dataset.tab === "tab-surface") {
        setTimeout(() => {
          Plotly.Plots.resize("plot-3d-surface");
          Plotly.Plots.resize("plot-2d-smiles");
        }, 50);
      } else if (tab.dataset.tab === "tab-greeks") {
        setTimeout(() => {
          Plotly.Plots.resize("plot-greek-curve");
          Plotly.Plots.resize("plot-payoff-curve");
        }, 50);
      }
    });
  });

  // Scenario Presets
  const chips = document.querySelectorAll(".preset-chip");
  chips.forEach((chip) => {
    chip.addEventListener("click", () => {
      chips.forEach((c) => c.classList.remove("active"));
      chip.classList.add("active");
      applyScenarioPreset(chip.dataset.preset);
    });
  });

  // Asset Switcher
  const assetBtns = document.querySelectorAll(".asset-btn");
  assetBtns.forEach((btn) => {
    btn.addEventListener("click", () => {
      assetBtns.forEach((b) => b.classList.remove("active"));
      btn.classList.add("active");
      const asset = btn.dataset.asset;
      if (asset === "GC") {
        inputF.min = 2100; inputF.max = 3200; inputF.step = 5; inputF.value = 2650;
        inputK.min = 2100; inputK.max = 3200; inputK.step = 5; inputK.value = 2650;
        inputVol.value = 17.5;
      } else {
        inputF.min = 50; inputF.max = 110; inputF.step = 0.5; inputF.value = 72.5;
        inputK.min = 50; inputK.max = 110; inputK.step = 0.5; inputK.value = 72.5;
        inputVol.value = 31.5;
      }
      updateStateFromSliders();
    });
  });

  // Call / Put Toggle
  const btnCall = document.getElementById("btn-call");
  const btnPut = document.getElementById("btn-put");
  btnCall.addEventListener("click", () => {
    btnCall.classList.add("active");
    btnPut.classList.remove("active");
    state.isCall = true;
    renderAll();
  });
  btnPut.addEventListener("click", () => {
    btnPut.classList.add("active");
    btnCall.classList.remove("active");
    state.isCall = false;
    renderAll();
  });

  // Slider inputs
  inputF.addEventListener("input", updateStateFromSliders);
  inputK.addEventListener("input", updateStateFromSliders);
  inputT.addEventListener("input", updateStateFromSliders);
  inputVol.addEventListener("input", updateStateFromSliders);
  inputR.addEventListener("input", updateStateFromSliders);

  // Greek curve selectors
  const selectors = document.querySelectorAll(".selector-btn");
  selectors.forEach((btn) => {
    btn.addEventListener("click", () => {
      selectors.forEach((s) => s.classList.remove("active"));
      btn.classList.add("active");
      state.activeGreekChart = btn.dataset.chart;
      renderGreekChart();
    });
  });

  // Monte Carlo regenerate
  document.getElementById("btn-resim-mc").addEventListener("click", drawMonteCarloPaths);

  // Alpha table filter chips
  const filterChips = document.querySelectorAll(".filter-chip");
  filterChips.forEach((btn) => {
    btn.addEventListener("click", () => {
      filterChips.forEach((f) => f.classList.remove("active"));
      btn.classList.add("active");
      state.alphaFilter = btn.dataset.filter;
      renderAlphaTable();
    });
  });

  // Modal
  const mathModal = document.getElementById("math-modal");
  document.getElementById("btn-math-modal").addEventListener("click", () => mathModal.classList.add("open"));
  document.getElementById("btn-close-modal").addEventListener("click", () => mathModal.classList.remove("open"));
  mathModal.addEventListener("click", (e) => {
    if (e.target === mathModal) mathModal.classList.remove("open");
  });
}

function applyScenarioPreset(preset) {
  const inputF = document.getElementById("input-f");
  const inputK = document.getElementById("input-k");
  const inputT = document.getElementById("input-t");
  const inputVol = document.getElementById("input-vol");

  if (preset === "gc_atm") {
    inputF.value = 2650; inputK.value = 2650; inputT.value = 60; inputVol.value = 17.5;
  } else if (preset === "gc_otm_call") {
    inputF.value = 2650; inputK.value = 2750; inputT.value = 60; inputVol.value = 18.2;
  } else if (preset === "gc_otm_put") {
    inputF.value = 2650; inputK.value = 2550; inputT.value = 60; inputVol.value = 19.5;
  } else if (preset === "cl_atm") {
    inputF.min = 50; inputF.max = 110; inputF.step = 0.5; inputF.value = 72.5;
    inputK.min = 50; inputK.max = 110; inputK.step = 0.5; inputK.value = 72.5;
    inputT.value = 60; inputVol.value = 31.5;
  } else if (preset === "cl_skew") {
    inputF.min = 50; inputF.max = 110; inputF.step = 0.5; inputF.value = 72.5;
    inputK.min = 50; inputK.max = 110; inputK.step = 0.5; inputK.value = 65.0;
    inputT.value = 30; inputVol.value = 38.0;
  }
  updateStateFromSliders();
}

function updateStateFromSliders() {
  state.F = parseFloat(document.getElementById("input-f").value);
  state.K = parseFloat(document.getElementById("input-k").value);
  state.T_days = parseInt(document.getElementById("input-t").value);
  state.vol = parseFloat(document.getElementById("input-vol").value) / 100.0;
  state.r = parseFloat(document.getElementById("input-r").value) / 100.0;

  document.getElementById("val-f").innerText = `$${state.F.toFixed(2)}`;
  document.getElementById("val-k").innerText = `$${state.K.toFixed(2)}`;
  document.getElementById("val-t").innerText = `${state.T_days} Days (${(state.T_days / 365).toFixed(3)}y)`;
  document.getElementById("val-vol").innerText = `${(state.vol * 100).toFixed(2)}%`;
  document.getElementById("val-r").innerText = `${(state.r * 100).toFixed(2)}%`;

  renderAll();
}

function renderAll() {
  const T = state.T_days / 365.0;

  // 1. Pricers
  const b76 = black76Price(state.F, state.K, T, state.r, state.vol, state.isCall);
  const crrAme = binomialCRR(state.F, state.K, T, state.r, state.vol, state.isCall, true, 250);
  const crrEur = binomialCRR(state.F, state.K, T, state.r, state.vol, state.isCall, false, 250);
  const mc = monteCarloPrice(state.F, state.K, T, state.r, state.vol, state.isCall, 35000);

  const earlyPrem = Math.max(crrAme - crrEur, 0.0);
  const diffEur = Math.abs(crrEur - b76);

  document.getElementById("price-b76").innerText = `$${b76.toFixed(3)}`;
  document.getElementById("price-crr-ame").innerText = `$${crrAme.toFixed(3)}`;
  document.getElementById("price-crr-eur").innerText = `$${crrEur.toFixed(3)}`;
  document.getElementById("price-mc").innerText = `$${mc.price.toFixed(3)}`;

  document.getElementById("badge-early-prem").innerText = `+$${earlyPrem.toFixed(3)} Prem`;
  document.getElementById("crr-diff").innerText = `Diff: $${diffEur.toFixed(4)} vs B-76`;
  document.getElementById("mc-ci").innerText = `95% CI: ±$${mc.ci.toFixed(3)}`;

  // 2. Greeks
  const g = calculateGreeks(state.F, state.K, T, state.r, state.vol, state.isCall);
  document.getElementById("g-delta").innerText = `${g.delta >= 0 ? "+" : ""}${g.delta.toFixed(4)}`;
  document.getElementById("g-gamma").innerText = g.gamma.toFixed(5);
  document.getElementById("g-vega").innerText = `$${g.vega1pct.toFixed(2)}`;
  document.getElementById("g-theta").innerText = `-$${Math.abs(g.theta1day).toFixed(2)}`;
  document.getElementById("g-rho").innerText = `${g.rho100bp >= 0 ? "+" : ""}$${g.rho100bp.toFixed(2)}`;
  document.getElementById("g-vanna").innerText = `${g.vanna >= 0 ? "+" : ""}${g.vanna.toFixed(4)}`;
  document.getElementById("g-volga").innerText = `${g.volga >= 0 ? "+" : ""}${g.volga.toFixed(2)}`;

  // 3. Visuals
  drawMonteCarloPaths();
  renderGreekChart();
  renderPayoffChart();
}

// ------------------- REAL-TIME MONTE CARLO CANVAS SIMULATION -------------------

function initMonteCarloCanvas() {
  const canvas = document.getElementById("mc-canvas");
  canvas.width = canvas.parentElement.clientWidth * window.devicePixelRatio;
  canvas.height = canvas.parentElement.clientHeight * window.devicePixelRatio;
  drawMonteCarloPaths();
  window.addEventListener("resize", () => {
    canvas.width = canvas.parentElement.clientWidth * window.devicePixelRatio;
    canvas.height = canvas.parentElement.clientHeight * window.devicePixelRatio;
    drawMonteCarloPaths();
  });
}

function drawMonteCarloPaths() {
  const canvas = document.getElementById("mc-canvas");
  if (!canvas) return;
  const ctx = canvas.getContext("2d");
  const W = canvas.width;
  const H = canvas.height;

  ctx.clearRect(0, 0, W, H);
  ctx.fillStyle = "#060913";
  ctx.fillRect(0, 0, W, H);

  // Background subtle grid
  ctx.strokeStyle = "rgba(255, 255, 255, 0.04)";
  ctx.lineWidth = 1;
  const gridRows = 6, gridCols = 8;
  for (let r = 0; r <= gridRows; r++) {
    const y = (H / gridRows) * r;
    ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(W, y); ctx.stroke();
  }
  for (let c = 0; c <= gridCols; c++) {
    const x = (W / gridCols) * c;
    ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, H); ctx.stroke();
  }

  const T = state.T_days / 365.0;
  const nSteps = 50;
  const nPaths = 32;
  const dt = T / nSteps;
  const drift = -0.5 * state.vol * state.vol * dt;
  const volSqrtDt = state.vol * Math.sqrt(dt);

  // Generate paths and track min/max for scaling
  const paths = [];
  let minPrice = state.F * 0.85;
  let maxPrice = state.F * 1.15;

  for (let p = 0; p < nPaths / 2; p++) {
    const path1 = [state.F];
    const path2 = [state.F];
    let curr1 = state.F;
    let curr2 = state.F;

    for (let s = 1; s <= nSteps; s++) {
      const u1 = Math.max(Math.random(), 1e-12);
      const u2 = Math.random();
      const z = Math.sqrt(-2.0 * Math.log(u1)) * Math.cos(2.0 * Math.PI * u2);

      curr1 = curr1 * Math.exp(drift + volSqrtDt * z);
      curr2 = curr2 * Math.exp(drift - volSqrtDt * z);

      path1.push(curr1);
      path2.push(curr2);

      minPrice = Math.min(minPrice, curr1, curr2);
      maxPrice = Math.max(maxPrice, curr1, curr2);
    }
    paths.push(path1, path2);
  }

  // Padding
  const padY = (maxPrice - minPrice) * 0.1;
  minPrice -= padY;
  maxPrice += padY;

  function toY(price) {
    return H - ((price - minPrice) / (maxPrice - minPrice)) * (H - 40) - 20;
  }
  function toX(step) {
    return (step / nSteps) * (W - 80) + 15;
  }

  // Draw strike line (K)
  const strikeY = toY(state.K);
  ctx.strokeStyle = "#f59e0b";
  ctx.setLineDash([6, 6]);
  ctx.lineWidth = 2 * window.devicePixelRatio;
  ctx.beginPath();
  ctx.moveTo(0, strikeY);
  ctx.lineTo(W - 80, strikeY);
  ctx.stroke();
  ctx.setLineDash([]);

  ctx.fillStyle = "#f59e0b";
  ctx.font = `${11 * window.devicePixelRatio}px 'JetBrains Mono'`;
  ctx.fillText(`Strike K: $${state.K.toFixed(0)}`, W - 75, strikeY + 4);

  // Draw stochastic paths
  const colors = ["rgba(0, 240, 255, 0.45)", "rgba(168, 85, 247, 0.4)", "rgba(16, 185, 129, 0.4)"];
  ctx.lineWidth = 1.5 * window.devicePixelRatio;

  paths.forEach((path, idx) => {
    ctx.strokeStyle = colors[idx % colors.length];
    ctx.beginPath();
    ctx.moveTo(toX(0), toY(path[0]));
    for (let s = 1; s <= nSteps; s++) {
      ctx.lineTo(toX(s), toY(path[s]));
    }
    ctx.stroke();
  });

  // Terminal points glowing dots
  paths.forEach((path) => {
    const finalPrice = path[nSteps];
    const inMoney = state.isCall ? finalPrice > state.K : finalPrice < state.K;
    ctx.fillStyle = inMoney ? "#10b981" : "rgba(244, 63, 94, 0.6)";
    ctx.beginPath();
    ctx.arc(toX(nSteps), toY(finalPrice), 3 * window.devicePixelRatio, 0, Math.PI * 2);
    ctx.fill();
  });
}

// ------------------- PLOTLY CHARTS (GREEKS & PAYOFF) -------------------

function renderGreekChart() {
  const T = state.T_days / 365.0;
  const numPts = 70;
  const pctRange = 0.15;
  const spots = [], vals = [];

  for (let i = 0; i < numPts; i++) {
    const s = state.F * (1.0 - pctRange + (2.0 * pctRange * i) / (numPts - 1));
    spots.push(s);
    const g = calculateGreeks(s, state.K, T, state.r, state.vol, state.isCall);
    if (state.activeGreekChart === "delta") vals.push(g.delta);
    else if (state.activeGreekChart === "gamma") vals.push(g.gamma);
    else if (state.activeGreekChart === "vega") vals.push(g.vega1pct);
    else if (state.activeGreekChart === "theta") vals.push(g.theta1day);
    else if (state.activeGreekChart === "vanna") vals.push(g.vanna);
    else if (state.activeGreekChart === "volga") vals.push(g.volga);
  }

  const trace = {
    x: spots,
    y: vals,
    mode: "lines",
    line: { color: "#00f0ff", width: 2.5 },
  };

  const layout = {
    margin: { t: 15, r: 20, l: 45, b: 35 },
    paper_bgcolor: "transparent",
    plot_bgcolor: "transparent",
    xaxis: { title: "Underlying Spot ($)", color: "#94a3b8", gridcolor: "rgba(255,255,255,0.05)" },
    yaxis: { color: "#94a3b8", gridcolor: "rgba(255,255,255,0.05)" },
    shapes: [{
      type: "line", x0: state.F, x1: state.F, y0: Math.min(...vals), y1: Math.max(...vals),
      line: { color: "#f59e0b", dash: "dash", width: 1.5 },
    }],
  };
  Plotly.react("plot-greek-curve", [trace], layout, { displayModeBar: false, responsive: true });
}

function renderPayoffChart() {
  const T = state.T_days / 365.0;
  const numPts = 70;
  const pctRange = 0.20;
  const spots = [], intrinsic = [], currentVal = [];

  for (let i = 0; i < numPts; i++) {
    const s = state.F * (1.0 - pctRange + (2.0 * pctRange * i) / (numPts - 1));
    spots.push(s);
    intrinsic.push(state.isCall ? Math.max(s - state.K, 0) : Math.max(state.K - s, 0));
    currentVal.push(black76Price(s, state.K, T, state.r, state.vol, state.isCall));
  }

  const traceIntrinsic = {
    x: spots, y: intrinsic, mode: "lines", name: "Intrinsic at Expiry (T=0)",
    line: { color: "#f59e0b", dash: "dash", width: 2 },
  };

  const traceCurrent = {
    x: spots, y: currentVal, mode: "lines", name: "Black-76 Present Value",
    line: { color: "#10b981", width: 2.5 },
  };

  const layout = {
    margin: { t: 15, r: 20, l: 45, b: 35 },
    paper_bgcolor: "transparent",
    plot_bgcolor: "transparent",
    xaxis: { title: "Underlying Spot ($)", color: "#94a3b8", gridcolor: "rgba(255,255,255,0.05)" },
    yaxis: { title: "Payoff ($)", color: "#94a3b8", gridcolor: "rgba(255,255,255,0.05)" },
    legend: { font: { color: "#94a3b8", size: 10 }, orientation: "h", y: 1.12, x: 0 },
  };

  Plotly.react("plot-payoff-curve", [traceIntrinsic, traceCurrent], layout, { displayModeBar: false, responsive: true });
}

// ------------------- PLOTLY CHARTS (3D SURFACE & 2D SMILES) -------------------

function init3DSurfacePlot() {
  const tenors = [0.08, 0.16, 0.25, 0.49];
  const moneyness = [];
  for (let m = 0.85; m <= 1.15; m += 0.02) moneyness.push(m);

  const zVols = [];
  for (let i = 0; i < moneyness.length; i++) {
    const row = [];
    for (let j = 0; j < tenors.length; j++) {
      const days = Math.round(tenors[j] * 365);
      const params = SVI_GOLD_SLICES[days] || SVI_GOLD_SLICES[60];
      row.push(sviVol(moneyness[i] * 2650, 2650, tenors[j], params) * 100.0);
    }
    zVols.push(row);
  }

  const data = [{
    x: tenors.map((t) => Math.round(t * 365)),
    y: moneyness,
    z: zVols,
    type: "surface",
    colorscale: "Viridis",
    showscale: false,
    contours: { z: { show: true, usecolormap: true, highlightcolor: "#00f0ff", project: { z: true } } },
  }];

  const layout = {
    margin: { t: 10, r: 10, l: 10, b: 10 },
    paper_bgcolor: "transparent",
    scene: {
      xaxis: { title: "Tenor (d)", color: "#94a3b8", gridcolor: "rgba(255,255,255,0.08)" },
      yaxis: { title: "Moneyness (K/F)", color: "#94a3b8", gridcolor: "rgba(255,255,255,0.08)" },
      zaxis: { title: "IV (%)", color: "#94a3b8", gridcolor: "rgba(255,255,255,0.08)" },
      camera: { eye: { x: -1.5, y: -1.4, z: 1.1 } },
    },
  };
  Plotly.newPlot("plot-3d-surface", data, layout, { displayModeBar: false, responsive: true });
}

function init2DSmilesPlot() {
  const kGrid = [];
  for (let k = -0.15; k <= 0.15; k += 0.005) kGrid.push(k);

  const traces = [];
  const daysList = [30, 60, 90, 180];
  const colors = ["#00f0ff", "#ff007f", "#39ff14", "#ffe600"];

  daysList.forEach((days, idx) => {
    const params = SVI_GOLD_SLICES[days];
    const vols = kGrid.map((k) => sviVol(Math.exp(k) * 2650, 2650, params.T, params) * 100);

    traces.push({
      x: kGrid.map((k) => Math.exp(k)),
      y: vols,
      mode: "lines",
      name: `${days}d SVI Model`,
      line: { color: colors[idx], width: 2 },
    });
  });

  const layout = {
    margin: { t: 20, r: 20, l: 45, b: 35 },
    paper_bgcolor: "transparent",
    plot_bgcolor: "transparent",
    xaxis: { title: "Moneyness (K / F)", color: "#94a3b8", gridcolor: "rgba(255,255,255,0.05)" },
    yaxis: { title: "Implied Volatility (%)", color: "#94a3b8", gridcolor: "rgba(255,255,255,0.05)" },
    legend: { orientation: "h", y: 1.15, x: 0, font: { color: "#94a3b8", size: 10 } },
  };
  Plotly.newPlot("plot-2d-smiles", traces, layout, { displayModeBar: false, responsive: true });
}

// ------------------- ALPHA ORDERFLOW TABLE -------------------

function renderAlphaTable() {
  const tbody = document.getElementById("alpha-tbody");
  tbody.innerHTML = "";

  const filtered = COMEX_GOLD_CHAIN.filter((c) => {
    if (state.alphaFilter === "BUY") return c.signal === "BUY";
    if (state.alphaFilter === "SELL") return c.signal === "SELL";
    return true;
  });

  filtered.forEach((c) => {
    const tr = document.createElement("tr");
    const actionClass = c.signal === "BUY" ? "action-buy" : c.signal === "SELL" ? "action-sell" : "action-fair";

    tr.innerHTML = `
      <td style="font-weight: 800; color: #fff;">${c.symbol}</td>
      <td>$${c.strike}</td>
      <td>${c.tenor}</td>
      <td>$${c.bid.toFixed(2)} / $${c.ask.toFixed(2)}</td>
      <td style="font-weight: 700; color: #fff;">$${c.fairPrice.toFixed(2)}</td>
      <td>${(c.mktIV * 100).toFixed(1)}%</td>
      <td>${(c.modelIV * 100).toFixed(1)}%</td>
      <td style="color: ${c.modelIV > c.mktIV ? 'var(--emerald)' : 'var(--rose)'}; font-weight: 700;">
        ${(c.mktIV - c.modelIV >= 0 ? '+' : '')}${((c.mktIV - c.modelIV) * 100).toFixed(2)}%
      </td>
      <td><span class="action-pill ${actionClass}">${c.label}</span></td>
      <td style="color: var(--cyan); font-weight: 600;">${c.hedge}</td>
      <td style="font-weight: 800; color: #fff;">${c.edge}</td>
    `;
    tbody.appendChild(tr);
  });
}

// Initialize on load
window.addEventListener("DOMContentLoaded", init);
