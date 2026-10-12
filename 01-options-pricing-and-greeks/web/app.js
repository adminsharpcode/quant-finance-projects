/**
 * Institutional Options Pricing, Greeks & Volatility Surface Engine (Web Kernel)
 * Implements Black-76, CRR American Lattice, Antithetic Monte Carlo,
 * SVI Gatheral Surface, and Systematic Relative-Value Arbitrage.
 */

// ------------------- MATHEMATICAL KERNEL -------------------

// High-precision standard normal cumulative distribution function (Abramowitz & Stegun 7.1.26)
function normCdf(x) {
  const a1 = 0.254829592;
  const a2 = -0.284496736;
  const a3 = 1.421413741;
  const a4 = -1.453152027;
  const a5 = 1.061405429;
  const p = 0.3275911;

  const sign = x < 0 ? -1 : 1;
  const absX = Math.abs(x) / Math.SQRT2;

  const t = 1.0 / (1.0 + p * absX);
  const y = 1.0 - (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * Math.exp(-absX * absX);

  return 0.5 * (1.0 + sign * y);
}

// Standard normal probability density function
function normPdf(x) {
  return (1.0 / Math.sqrt(2.0 * Math.PI)) * Math.exp(-0.5 * x * x);
}

// Normalized Black-76 coordinates d1 and d2
function d1_d2(F, K, T, sigma) {
  const volSqrtT = Math.max(sigma * Math.sqrt(Math.max(T, 1e-4)), 1e-6);
  const d1 = (Math.log(Math.max(F, 1e-4) / Math.max(K, 1e-4)) + 0.5 * sigma * sigma * T) / volSqrtT;
  const d2 = d1 - volSqrtT;
  return { d1, d2 };
}

// Black-76 Closed-Form Pricing for Futures (COMEX/CME Standard)
function black76Price(F, K, T, r, sigma, isCall) {
  if (T <= 0) {
    return isCall ? Math.max(F - K, 0) : Math.max(K - F, 0);
  }
  const { d1, d2 } = d1_d2(F, K, T, sigma);
  const discount = Math.exp(-r * T);

  if (isCall) {
    return discount * (F * normCdf(d1) - K * normCdf(d2));
  } else {
    return discount * (K * normCdf(-d2) - F * normCdf(-d1));
  }
}

// Cox-Ross-Rubinstein (CRR) Binomial Lattice for American & European Options
function binomialCRR(F, K, T, r, sigma, isCall, isAmerican, steps = 300) {
  if (T <= 0) {
    return isCall ? Math.max(F - K, 0) : Math.max(K - F, 0);
  }
  const n = Math.max(steps, 20);
  const dt = T / n;
  const u = Math.exp(sigma * Math.sqrt(dt));
  const d = 1.0 / u;
  // For futures under Q, risk-neutral drift is zero, so p = (1 - d) / (u - d)
  let p = (1.0 - d) / (u - d);
  p = Math.min(Math.max(p, 0.0), 1.0);

  const discount = Math.exp(-r * dt);

  // Terminal values
  let values = new Float64Array(n + 1);
  for (let j = 0; j <= n; j++) {
    const terminalPrice = F * Math.pow(u, j) * Math.pow(d, n - j);
    values[j] = isCall ? Math.max(terminalPrice - K, 0) : Math.max(K - terminalPrice, 0);
  }

  // Backward induction
  for (let i = n - 1; i >= 0; i--) {
    let nextValues = new Float64Array(i + 1);
    for (let j = 0; j <= i; j++) {
      const continuation = discount * (p * values[j + 1] + (1.0 - p) * values[j]);
      if (isAmerican) {
        const currentUnderlying = F * Math.pow(u, j) * Math.pow(d, i - j);
        const intrinsic = isCall ? Math.max(currentUnderlying - K, 0) : Math.max(K - currentUnderlying, 0);
        nextValues[j] = Math.max(continuation, intrinsic);
      } else {
        nextValues[j] = continuation;
      }
    }
    values = nextValues;
  }

  return values[0];
}

// Monte Carlo Pricing with Antithetic Variates
function monteCarloPrice(F, K, T, r, sigma, isCall, paths = 40000) {
  if (T <= 0) {
    return { price: isCall ? Math.max(F - K, 0) : Math.max(K - F, 0), se: 0, ci: 0 };
  }
  const halfPaths = paths / 2;
  const drift = -0.5 * sigma * sigma * T;
  const volSqrtT = sigma * Math.sqrt(T);
  const discount = Math.exp(-r * T);

  let sum = 0.0;
  let sumSq = 0.0;

  for (let i = 0; i < halfPaths; i++) {
    // Box-Muller standard normal draw
    const u1 = Math.max(Math.random(), 1e-12);
    const u2 = Math.random();
    const z = Math.sqrt(-2.0 * Math.log(u1)) * Math.cos(2.0 * Math.PI * u2);

    const fT1 = F * Math.exp(drift + volSqrtT * z);
    const fT2 = F * Math.exp(drift - volSqrtT * z);

    const payoff1 = discount * (isCall ? Math.max(fT1 - K, 0) : Math.max(K - fT1, 0));
    const payoff2 = discount * (isCall ? Math.max(fT2 - K, 0) : Math.max(K - fT2, 0));

    const avgPayoff = 0.5 * (payoff1 + payoff2);
    sum += avgPayoff;
    sumSq += avgPayoff * avgPayoff;
  }

  const mean = sum / halfPaths;
  const variance = Math.max((sumSq - (sum * sum) / halfPaths) / (halfPaths - 1), 0);
  const se = Math.sqrt(variance / halfPaths);

  return { price: mean, se: se, ci: 1.96 * se };
}

// ------------------- GREEKS ENGINE -------------------

function calculateGreeks(F, K, T, r, sigma, isCall) {
  const { d1, d2 } = d1_d2(F, K, T, sigma);
  const discount = Math.exp(-r * T);
  const sqrtT = Math.sqrt(Math.max(T, 1e-4));
  const pdfD1 = normPdf(d1);

  // Delta on Futures: dV / dF
  const delta = isCall ? discount * normCdf(d1) : -discount * normCdf(-d1);

  // Gamma: d^2V / dF^2
  const gamma = (discount * pdfD1) / (F * sigma * sqrtT);

  // Vega: dV / d_sigma (raw and 1%)
  const vega = discount * F * sqrtT * pdfD1;
  const vega1pct = vega * 0.01;

  // Theta: dV / dt (annualized and 1-day)
  const term1 = -(discount * F * pdfD1 * sigma) / (2.0 * sqrtT);
  const term2 = -r * black76Price(F, K, T, r, sigma, isCall);
  const thetaAnnual = term1 + term2;
  const theta1day = thetaAnnual / 365.0;

  // Rho: dV / dr (for futures = -T * price)
  const price = black76Price(F, K, T, r, sigma, isCall);
  const rho100bp = (-T * price) * 0.01;

  // Vanna: d^2V / (dF d_sigma) = dDelta / dVol
  const vanna = -discount * pdfD1 * (d2 / sigma);

  // Volga (Vomma): d^2V / d_sigma^2
  const volga = vega * (d1 * d2) / sigma;

  return {
    price,
    delta,
    gamma,
    vega1pct,
    theta1day,
    rho100bp,
    vanna,
    volga,
  };
}

// ------------------- SVI SURFACE KERNEL -------------------

function sviTotalVariance(k, a, b, rho, m, sigma) {
  const diff = k - m;
  return a + b * (rho * diff + Math.sqrt(diff * diff + sigma * sigma));
}

function sviVol(K, F, T, params) {
  const k = Math.log(K / F);
  const w = sviTotalVariance(k, params.a, params.b, params.rho, params.m, params.sigma);
  return Math.sqrt(Math.max(w, 1e-8) / Math.max(T, 1e-4));
}

// Pre-calibrated SVI parameters for COMEX Gold
const SVI_GOLD_SLICES = {
  30: { a: 0.0001, b: 0.0695, rho: 0.8480, m: 0.1500, sigma: 0.0524, T: 30 / 365 },
  60: { a: 0.0027, b: 0.0032, rho: -0.9009, m: 0.3406, sigma: 0.0010, T: 60 / 365 },
  90: { a: 0.0061, b: 0.0072, rho: -0.9900, m: 0.0368, sigma: 0.1588, T: 90 / 365 },
  180: { a: 0.0141, b: 0.0126, rho: -0.9900, m: 0.0300, sigma: 0.1473, T: 180 / 365 },
};

// Authentic COMEX Gold Options Chain Snapshot
const COMEX_GOLD_CHAIN = [
  { symbol: "OG_2490_P_30d", strike: 2490, tenor: "30d", T: 30 / 365, type: "put", bid: 6.13, ask: 7.13, fairPrice: 7.43, mktIV: 0.175, modelIV: 0.181, signal: "BUY_VOL (Cheap Gamma)", hedge: "+0.142 GC", edge: "+$0.30" },
  { symbol: "OG_2550_C_30d", strike: 2550, tenor: "30d", T: 30 / 365, type: "call", bid: 112.50, ask: 114.50, fairPrice: 113.40, mktIV: 0.172, modelIV: 0.171, signal: "FAIR_VALUE", hedge: "-0.738 GC", edge: "$0.00" },
  { symbol: "OG_2650_C_60d", strike: 2650, tenor: "60d", T: 60 / 365, type: "call", bid: 73.80, ask: 75.20, fairPrice: 74.55, mktIV: 0.175, modelIV: 0.175, signal: "FAIR_VALUE", hedge: "-0.503 GC", edge: "$0.00" },
  { symbol: "OG_2700_C_30d", strike: 2700, tenor: "30d", T: 30 / 365, type: "call", bid: 28.10, ask: 29.10, fairPrice: 27.72, mktIV: 0.163, modelIV: 0.159, signal: "SELL_VOL (Harvest Prem)", hedge: "-0.385 GC", edge: "+$0.38" },
  { symbol: "OG_2730_C_30d", strike: 2730, tenor: "30d", T: 30 / 365, type: "call", bid: 18.45, ask: 19.45, fairPrice: 18.18, mktIV: 0.160, modelIV: 0.157, signal: "SELL_VOL (Harvest Prem)", hedge: "-0.275 GC", edge: "+$0.27" },
  { symbol: "OG_2760_C_30d", strike: 2760, tenor: "30d", T: 30 / 365, type: "call", bid: 12.15, ask: 13.15, fairPrice: 11.86, mktIV: 0.159, modelIV: 0.155, signal: "SELL_VOL (Harvest Prem)", hedge: "-0.198 GC", edge: "+$0.29" },
  { symbol: "OG_2800_C_60d", strike: 2800, tenor: "60d", T: 60 / 365, type: "call", bid: 22.40, ask: 23.60, fairPrice: 23.00, mktIV: 0.182, modelIV: 0.182, signal: "FAIR_VALUE", hedge: "-0.210 GC", edge: "$0.00" },
];

// ------------------- APPLICATION CONTROLLER -------------------

let state = {
  F: 2650.0,
  K: 2650.0,
  T_days: 60,
  vol: 0.175,
  r: 0.045,
  isCall: true,
  activeGreekChart: "delta",
};

function init() {
  bindControls();
  renderAll();
  init3DSurfacePlot();
  init2DSmilesPlot();
  initAlphaTable();
}

function bindControls() {
  const assetSelect = document.getElementById("asset-select");
  const inputF = document.getElementById("input-f");
  const inputK = document.getElementById("input-k");
  const inputT = document.getElementById("input-t");
  const inputVol = document.getElementById("input-vol");
  const inputR = document.getElementById("input-r");

  assetSelect.addEventListener("change", (e) => {
    if (e.target.value === "GC") {
      inputF.min = 2000; inputF.max = 3200; inputF.step = 5; inputF.value = 2650;
      inputK.min = 2000; inputK.max = 3200; inputK.step = 5; inputK.value = 2650;
      inputVol.value = 17.5;
    } else if (e.target.value === "CL") {
      inputF.min = 50; inputF.max = 110; inputF.step = 0.5; inputF.value = 72.5;
      inputK.min = 50; inputK.max = 110; inputK.step = 0.5; inputK.value = 72.5;
      inputVol.value = 31.5;
    }
    updateStateFromInputs();
  });

  inputF.addEventListener("input", updateStateFromInputs);
  inputK.addEventListener("input", updateStateFromInputs);
  inputT.addEventListener("input", updateStateFromInputs);
  inputVol.addEventListener("input", updateStateFromInputs);
  inputR.addEventListener("input", updateStateFromInputs);

  // Option Type Toggle
  const toggleBtns = document.querySelectorAll("#opt-type-toggle .toggle-btn");
  toggleBtns.forEach((btn) => {
    btn.addEventListener("click", () => {
      toggleBtns.forEach((b) => b.classList.remove("active"));
      btn.classList.add("active");
      state.isCall = btn.dataset.type === "call";
      renderAll();
    });
  });

  // Greek Chart Pill Buttons
  const greekPills = document.querySelectorAll(".chart-controls .pill-btn");
  greekPills.forEach((pill) => {
    pill.addEventListener("click", () => {
      greekPills.forEach((p) => p.classList.remove("active"));
      pill.classList.add("active");
      state.activeGreekChart = pill.dataset.chartGreek;
      renderGreekChart();
    });
  });

  // Modal
  const mathBtn = document.getElementById("btn-math-modal");
  const closeBtn = document.getElementById("btn-close-modal");
  const modal = document.getElementById("math-modal");

  mathBtn.addEventListener("click", () => modal.classList.add("open"));
  closeBtn.addEventListener("click", () => modal.classList.remove("open"));
  modal.addEventListener("click", (e) => {
    if (e.target === modal) modal.classList.remove("open");
  });
}

function updateStateFromInputs() {
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

  // 1. Pricer Calculations
  const b76 = black76Price(state.F, state.K, T, state.r, state.vol, state.isCall);
  const crrAme = binomialCRR(state.F, state.K, T, state.r, state.vol, state.isCall, true, 200);
  const crrEur = binomialCRR(state.F, state.K, T, state.r, state.vol, state.isCall, false, 200);
  const mc = monteCarloPrice(state.F, state.K, T, state.r, state.vol, state.isCall, 30000);

  const earlyPrem = Math.max(crrAme - crrEur, 0.0);

  document.getElementById("card-price-b76").innerText = `$${b76.toFixed(3)}`;
  document.getElementById("card-price-crr-ame").innerText = `$${crrAme.toFixed(3)}`;
  document.getElementById("card-price-crr-eur").innerText = `$${crrEur.toFixed(3)}`;
  document.getElementById("card-price-mc").innerText = `$${mc.price.toFixed(3)}`;
  document.getElementById("mc-ci").innerText = `95% CI: ±$${mc.ci.toFixed(3)}`;
  document.getElementById("badge-early-prem").innerText = `+$${earlyPrem.toFixed(3)} Prem`;

  // 2. Greeks Calculations
  const g = calculateGreeks(state.F, state.K, T, state.r, state.vol, state.isCall);
  document.getElementById("g-delta").innerText = `${g.delta >= 0 ? "+" : ""}${g.delta.toFixed(4)}`;
  document.getElementById("g-gamma").innerText = g.gamma.toFixed(5);
  document.getElementById("g-vega").innerText = `$${g.vega1pct.toFixed(2)}`;
  document.getElementById("g-theta").innerText = `-$${Math.abs(g.theta1day).toFixed(2)}`;
  document.getElementById("g-rho").innerText = `${g.rho100bp >= 0 ? "+" : ""}$${g.rho100bp.toFixed(2)}`;
  document.getElementById("g-vanna").innerText = `${g.vanna >= 0 ? "+" : ""}${g.vanna.toFixed(4)}`;
  document.getElementById("g-volga").innerText = `${g.volga >= 0 ? "+" : ""}${g.volga.toFixed(2)}`;

  renderGreekChart();
}

function renderGreekChart() {
  const T = state.T_days / 365.0;
  const numPoints = 60;
  const rangePct = 0.15;
  const spots = [];
  const vals = [];

  for (let i = 0; i < numPoints; i++) {
    const s = state.F * (1.0 - rangePct + (2.0 * rangePct * i) / (numPoints - 1));
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
    xaxis: {
      title: "Underlying Futures Price ($)",
      color: "#94a3b8",
      gridcolor: "rgba(255, 255, 255, 0.05)",
    },
    yaxis: {
      color: "#94a3b8",
      gridcolor: "rgba(255, 255, 255, 0.05)",
    },
    shapes: [
      {
        type: "line",
        x0: state.F,
        x1: state.F,
        y0: Math.min(...vals),
        y1: Math.max(...vals),
        line: { color: "#f59e0b", dash: "dash", width: 1.5 },
      },
    ],
  };

  Plotly.react("greek-chart", [trace], layout, { displayModeBar: false, responsive: true });
}

function init3DSurfacePlot() {
  const tenors = [0.08, 0.16, 0.25, 0.49];
  const moneyness = [];
  for (let m = 0.85; m <= 1.15; m += 0.02) moneyness.push(m);

  const zVols = [];

  for (let i = 0; i < moneyness.length; i++) {
    const row = [];
    const k = Math.log(moneyness[i]);
    for (let j = 0; j < tenors.length; j++) {
      const days = Math.round(tenors[j] * 365);
      const params = SVI_GOLD_SLICES[days] || SVI_GOLD_SLICES[60];
      const vol = sviVol(moneyness[i] * 2650, 2650, tenors[j], params);
      row.push(vol * 100.0);
    }
    zVols.push(row);
  }

  const data = [
    {
      x: tenors.map((t) => Math.round(t * 365)),
      y: moneyness,
      z: zVols,
      type: "surface",
      colorscale: "Viridis",
      showscale: false,
    },
  ];

  const layout = {
    margin: { t: 10, r: 10, l: 10, b: 10 },
    paper_bgcolor: "transparent",
    scene: {
      xaxis: { title: "Tenor (d)", color: "#94a3b8", gridcolor: "rgba(255, 255, 255, 0.1)" },
      yaxis: { title: "Moneyness (K/F)", color: "#94a3b8", gridcolor: "rgba(255, 255, 255, 0.1)" },
      zaxis: { title: "IV (%)", color: "#94a3b8", gridcolor: "rgba(255, 255, 255, 0.1)" },
      camera: { eye: { x: -1.5, y: -1.4, z: 1.1 } },
    },
  };

  Plotly.newPlot("surface-3d-plot", data, layout, { displayModeBar: false, responsive: true });
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
    xaxis: { title: "Moneyness (K / F)", color: "#94a3b8", gridcolor: "rgba(255, 255, 255, 0.05)" },
    yaxis: { title: "Implied Volatility (%)", color: "#94a3b8", gridcolor: "rgba(255, 255, 255, 0.05)" },
    legend: { orientation: "h", y: 1.15, x: 0, font: { color: "#94a3b8", size: 10 } },
  };

  Plotly.newPlot("smiles-2d-plot", traces, layout, { displayModeBar: false, responsive: true });
}

function initAlphaTable() {
  const tbody = document.getElementById("alpha-table-body");
  tbody.innerHTML = "";

  COMEX_GOLD_CHAIN.forEach((c) => {
    const tr = document.createElement("tr");

    const signalClass = c.signal.includes("BUY")
      ? "signal-buy"
      : c.signal.includes("SELL")
      ? "signal-sell"
      : "";

    tr.innerHTML = `
      <td style="font-weight: 700;">${c.symbol}</td>
      <td>$${c.strike}</td>
      <td>${c.tenor}</td>
      <td>$${c.bid.toFixed(2)} / $${c.ask.toFixed(2)}</td>
      <td style="font-weight: 600;">$${c.fairPrice.toFixed(2)}</td>
      <td>${(c.mktIV * 100).toFixed(1)}%</td>
      <td>${(c.modelIV * 100).toFixed(1)}%</td>
      <td style="color: ${c.modelIV > c.mktIV ? 'var(--accent-emerald)' : 'var(--accent-rose)'};">${(c.mktIV - c.modelIV >= 0 ? '+' : '')}${((c.mktIV - c.modelIV) * 100).toFixed(2)}%</td>
      <td class="${signalClass}">${c.signal}</td>
      <td style="color: var(--accent-cyan);">${c.hedge}</td>
      <td style="font-weight: 700; color: #fff;">${c.edge}</td>
    `;
    tbody.appendChild(tr);
  });
}

// Initialize on DOM load
window.addEventListener("DOMContentLoaded", init);
