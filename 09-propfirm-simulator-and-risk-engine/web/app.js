/**
 * PropFirm Alpha: Client-Side Stochastic Simulation Engine & Dashboard Controller
 * Simulates double-barrier stochastic first-passage paths across 22 prop firms.
 */

// Complete Catalog of 22 Prop Firms Embedded for Instant Offline Performance
const PROP_FIRMS = {
  ftmo_standard: {
    id: "ftmo_standard",
    name: "FTMO (Standard 2-Step)",
    market: "Forex & CFDs",
    phases: [{ target: 10.0, minDays: 4 }, { target: 5.0, minDays: 4 }],
    dailyDD: 5.0,
    maxDD: 10.0,
    ddType: "Static",
    split: 80,
    mdi: 1.50
  },
  ftmo_aggressive: {
    id: "ftmo_aggressive",
    name: "FTMO (Aggressive 2-Step)",
    market: "Forex & CFDs",
    phases: [{ target: 20.0, minDays: 4 }, { target: 10.0, minDays: 4 }],
    dailyDD: 10.0,
    maxDD: 20.0,
    ddType: "Static",
    split: 80,
    mdi: 1.35
  },
  funding_pips_2step: {
    id: "funding_pips_2step",
    name: "Funding Pips (Student 2-Step)",
    market: "Forex & CFDs",
    phases: [{ target: 8.0, minDays: 0 }, { target: 5.0, minDays: 0 }],
    dailyDD: 5.0,
    maxDD: 10.0,
    ddType: "Static",
    split: 85,
    mdi: 1.30
  },
  funding_pips_1step: {
    id: "funding_pips_1step",
    name: "Funding Pips (Master 1-Step)",
    market: "Forex & CFDs",
    phases: [{ target: 12.0, minDays: 0 }],
    dailyDD: 3.0,
    maxDD: 6.0,
    ddType: "Relative",
    split: 90,
    mdi: 2.95
  },
  the5ers_high_stakes: {
    id: "the5ers_high_stakes",
    name: "The 5%ers (High Stakes 2-Step)",
    market: "Forex & CFDs",
    phases: [{ target: 8.0, minDays: 3 }, { target: 5.0, minDays: 3 }],
    dailyDD: 5.0,
    maxDD: 10.0,
    ddType: "Static",
    split: 80,
    mdi: 1.30
  },
  the5ers_bootcamp: {
    id: "the5ers_bootcamp",
    name: "The 5%ers (Bootcamp 3-Step)",
    market: "Forex & CFDs",
    phases: [{ target: 6.0, minDays: 0 }, { target: 6.0, minDays: 0 }, { target: 6.0, minDays: 0 }],
    dailyDD: 0.0,
    maxDD: 5.0,
    ddType: "Static",
    split: 85,
    mdi: 3.60
  },
  topstep_combine: {
    id: "topstep_combine",
    name: "Topstep (Trading Combine Futures)",
    market: "CME Futures",
    phases: [{ target: 6.0, minDays: 2 }],
    dailyDD: 2.0,
    maxDD: 4.0,
    ddType: "Trailing_EOD",
    split: 90,
    mdi: 2.73
  },
  apex_futures: {
    id: "apex_futures",
    name: "Apex Trader Funding (Futures Trailing)",
    market: "CME Futures",
    phases: [{ target: 6.0, minDays: 1 }],
    dailyDD: 0.0,
    maxDD: 5.0,
    ddType: "Trailing_Intraday",
    split: 90,
    mdi: 2.64
  },
  fundednext_stellar_2step: {
    id: "fundednext_stellar_2step",
    name: "FundedNext (Stellar 2-Step)",
    market: "Forex & CFDs",
    phases: [{ target: 8.0, minDays: 5 }, { target: 5.0, minDays: 5 }],
    dailyDD: 5.0,
    maxDD: 10.0,
    ddType: "Static",
    split: 80,
    mdi: 1.30
  },
  fundednext_stellar_1step: {
    id: "fundednext_stellar_1step",
    name: "FundedNext (Stellar 1-Step)",
    market: "Forex & CFDs",
    phases: [{ target: 10.0, minDays: 2 }],
    dailyDD: 3.0,
    maxDD: 6.0,
    ddType: "Trailing_EOD",
    split: 90,
    mdi: 2.64
  },
  e8_markets_classic: {
    id: "e8_markets_classic",
    name: "E8 Markets (E8 Classic 2-Step)",
    market: "Forex & CFDs",
    phases: [{ target: 8.0, minDays: 0 }, { target: 4.0, minDays: 0 }],
    dailyDD: 4.0,
    maxDD: 8.0,
    ddType: "Relative",
    split: 80,
    mdi: 2.05
  },
  e8_markets_track: {
    id: "e8_markets_track",
    name: "E8 Markets (E8 Track 3-Step)",
    market: "Forex & CFDs",
    phases: [{ target: 5.0, minDays: 0 }, { target: 5.0, minDays: 0 }, { target: 5.0, minDays: 0 }],
    dailyDD: 4.0,
    maxDD: 8.0,
    ddType: "Relative",
    split: 80,
    mdi: 2.56
  },
  alpha_capital_pro: {
    id: "alpha_capital_pro",
    name: "Alpha Capital Group (Alpha Pro 2-Step)",
    market: "Forex & CFDs",
    phases: [{ target: 8.0, minDays: 0 }, { target: 5.0, minDays: 0 }],
    dailyDD: 5.0,
    maxDD: 10.0,
    ddType: "Static",
    split: 80,
    mdi: 1.30
  },
  city_traders_imperium: {
    id: "city_traders_imperium",
    name: "City Traders Imperium (Challenge 2-Step)",
    market: "Forex & CFDs",
    phases: [{ target: 9.0, minDays: 5 }, { target: 5.0, minDays: 5 }],
    dailyDD: 4.0,
    maxDD: 8.0,
    ddType: "Static",
    split: 80,
    mdi: 1.84
  },
  blue_guardian: {
    id: "blue_guardian",
    name: "Blue Guardian (Unlimited 2-Step)",
    market: "Forex & CFDs",
    phases: [{ target: 8.0, minDays: 0 }, { target: 4.0, minDays: 0 }],
    dailyDD: 4.0,
    maxDD: 8.0,
    ddType: "Static",
    split: 85,
    mdi: 1.58
  },
  the_funded_trader_standard: {
    id: "the_funded_trader_standard",
    name: "The Funded Trader (Standard 2-Step)",
    market: "Forex & CFDs",
    phases: [{ target: 10.0, minDays: 3 }, { target: 5.0, minDays: 3 }],
    dailyDD: 5.0,
    maxDD: 10.0,
    ddType: "Static",
    split: 80,
    mdi: 1.50
  },
  goat_funded_trader: {
    id: "goat_funded_trader",
    name: "Goat Funded Trader (Classic 2-Step)",
    market: "Forex & CFDs",
    phases: [{ target: 8.0, minDays: 0 }, { target: 5.0, minDays: 0 }],
    dailyDD: 4.0,
    maxDD: 8.0,
    ddType: "Static",
    split: 80,
    mdi: 1.71
  },
  fxify_2step: {
    id: "fxify_2step",
    name: "FXIFY (2-Step Assessment)",
    market: "Forex & CFDs",
    phases: [{ target: 10.0, minDays: 5 }, { target: 5.0, minDays: 5 }],
    dailyDD: 5.0,
    maxDD: 10.0,
    ddType: "Static",
    split: 85,
    mdi: 1.50
  },
  take_profit_trader: {
    id: "take_profit_trader",
    name: "Take Profit Trader (ProDay Futures)",
    market: "CME Futures",
    phases: [{ target: 6.0, minDays: 5 }],
    dailyDD: 2.2,
    maxDD: 4.0,
    ddType: "Trailing_EOD",
    split: 80,
    mdi: 2.63
  },
  tradeday_evaluation: {
    id: "tradeday_evaluation",
    name: "TradeDay (Futures Evaluation)",
    market: "CME Futures",
    phases: [{ target: 6.0, minDays: 7 }],
    dailyDD: 2.0,
    maxDD: 4.0,
    ddType: "Trailing_EOD",
    split: 90,
    mdi: 2.73
  },
  earn2trade_tcp: {
    id: "earn2trade_tcp",
    name: "Earn2Trade (Trader Career Path)",
    market: "CME Futures",
    phases: [{ target: 6.0, minDays: 10 }],
    dailyDD: 2.2,
    maxDD: 4.0,
    ddType: "Trailing_EOD",
    split: 80,
    mdi: 2.63
  },
  bulenox_master: {
    id: "bulenox_master",
    name: "Bulenox (Futures Master Trailing)",
    market: "CME Futures",
    phases: [{ target: 6.0, minDays: 5 }],
    dailyDD: 0.0,
    maxDD: 5.0,
    ddType: "Trailing_Intraday",
    split: 90,
    mdi: 2.64
  }
};

// Application State
let currentChart = null;
let currentFirmKey = "ftmo_standard";

// DOM Elements
const firmSelect = document.getElementById("firmSelect");
const accountSizeSelect = document.getElementById("accountSizeSelect");
const maxDaysSelect = document.getElementById("maxDaysSelect");
const winRateInput = document.getElementById("winRateInput");
const winRateVal = document.getElementById("winRateVal");
const rewardRiskInput = document.getElementById("rewardRiskInput");
const rewardRiskVal = document.getElementById("rewardRiskVal");
const riskPerTradeInput = document.getElementById("riskPerTradeInput");
const riskPerTradeVal = document.getElementById("riskPerTradeVal");
const tradesPerDayInput = document.getElementById("tradesPerDayInput");
const tradesPerDayVal = document.getElementById("tradesPerDayVal");
const runSimBtn = document.getElementById("runSimBtn");
const optimizeBtn = document.getElementById("optimizeBtn");
const resetDefaultsBtn = document.getElementById("resetDefaultsBtn");
const riskWarning = document.getElementById("riskWarning");

// KPI Elements
const kpiPassRate = document.getElementById("kpiPassRate");
const kpiRuinRate = document.getElementById("kpiRuinRate");
const kpiAvgDays = document.getElementById("kpiAvgDays");
const kpiMinDays = document.getElementById("kpiMinDays");
const kpiOptimalRisk = document.getElementById("kpiOptimalRisk");
const kpiMaxSafe = document.getElementById("kpiMaxSafe");
const firmRuleBadges = document.getElementById("firmRuleBadges");

// Tab Controls
const tabFanBtn = document.getElementById("tabFanBtn");
const tabFirmsBtn = document.getElementById("tabFirmsBtn");
const tabGuideBtn = document.getElementById("tabGuideBtn");
const tabFanContent = document.getElementById("tabFanContent");
const tabFirmsContent = document.getElementById("tabFirmsContent");
const tabGuideContent = document.getElementById("tabGuideContent");
const firmsTableBody = document.getElementById("firmsTableBody");

// Initialize application
function init() {
  populateFirmSelect();
  renderFirmsTable();
  setupEventListeners();
  updateFirmBadges();
  runSimulation();
}

function populateFirmSelect() {
  firmSelect.innerHTML = "";
  Object.keys(PROP_FIRMS).forEach(key => {
    const firm = PROP_FIRMS[key];
    const option = document.createElement("option");
    option.value = key;
    option.textContent = firm.name;
    firmSelect.appendChild(option);
  });
  firmSelect.value = currentFirmKey;
}

function updateFirmBadges() {
  const firm = PROP_FIRMS[currentFirmKey];
  const targetStr = firm.phases.map((p, idx) => `P${idx+1}: +${p.target}%`).join(", ");
  const minDaysStr = firm.phases.map((p, idx) => `P${idx+1}: ${p.minDays}d`).join(", ");

  firmRuleBadges.innerHTML = `
    <div class="flex justify-between items-center text-slate-300">
      <span class="text-slate-400">Market:</span>
      <span class="font-medium text-white">${firm.market}</span>
    </div>
    <div class="flex justify-between items-center text-slate-300">
      <span class="text-slate-400">Profit Targets:</span>
      <span class="font-medium text-emerald-400">${targetStr}</span>
    </div>
    <div class="flex justify-between items-center text-slate-300">
      <span class="text-slate-400">Daily Loss Limit:</span>
      <span class="font-medium text-amber-400">${firm.dailyDD > 0 ? firm.dailyDD + '%' : 'None'}</span>
    </div>
    <div class="flex justify-between items-center text-slate-300">
      <span class="text-slate-400">Max Drawdown:</span>
      <span class="font-medium text-rose-400">-${firm.maxDD}% (${firm.ddType})</span>
    </div>
    <div class="flex justify-between items-center text-slate-300">
      <span class="text-slate-400">Difficulty Index:</span>
      <span class="font-bold ${firm.mdi > 2.2 ? 'text-rose-400' : firm.mdi > 1.6 ? 'text-amber-400' : 'text-emerald-400'}">${firm.mdi.toFixed(2)} MDI</span>
    </div>
  `;

  // Check safety bound
  checkRiskSafety();
}

function checkRiskSafety() {
  const firm = PROP_FIRMS[currentFirmKey];
  const risk = parseFloat(riskPerTradeInput.value);
  const trades = parseInt(tradesPerDayInput.value);

  if (firm.dailyDD > 0) {
    const dailyExposure = risk * trades;
    const maxSafe = firm.dailyDD / (trades * 1.5);
    kpiMaxSafe.textContent = `${maxSafe.toFixed(2)}%`;

    if (risk > maxSafe) {
      riskWarning.textContent = `⚠️ High Risk: ${trades} consecutive losses will breach ${firm.dailyDD}% daily limit!`;
      riskWarning.classList.remove("hidden");
    } else {
      riskWarning.classList.add("hidden");
    }
  } else {
    const maxSafe = firm.maxDD / 6.0;
    kpiMaxSafe.textContent = `${maxSafe.toFixed(2)}%`;
    riskWarning.classList.add("hidden");
  }
}

function setupEventListeners() {
  firmSelect.addEventListener("change", (e) => {
    currentFirmKey = e.target.value;
    updateFirmBadges();
    runSimulation();
  });

  accountSizeSelect.addEventListener("change", runSimulation);
  maxDaysSelect.addEventListener("change", runSimulation);

  winRateInput.addEventListener("input", (e) => {
    winRateVal.textContent = `${e.target.value}%`;
    checkRiskSafety();
  });
  rewardRiskInput.addEventListener("input", (e) => {
    rewardRiskVal.textContent = parseFloat(e.target.value).toFixed(2);
    checkRiskSafety();
  });
  riskPerTradeInput.addEventListener("input", (e) => {
    riskPerTradeVal.textContent = `${parseFloat(e.target.value).toFixed(2)}%`;
    checkRiskSafety();
  });
  tradesPerDayInput.addEventListener("input", (e) => {
    tradesPerDayVal.textContent = e.target.value;
    checkRiskSafety();
  });

  runSimBtn.addEventListener("click", runSimulation);
  optimizeBtn.addEventListener("click", autoOptimizeRisk);

  resetDefaultsBtn.addEventListener("click", () => {
    winRateInput.value = 52;
    winRateVal.textContent = "52%";
    rewardRiskInput.value = 1.5;
    rewardRiskVal.textContent = "1.50";
    riskPerTradeInput.value = 0.75;
    riskPerTradeVal.textContent = "0.75%";
    tradesPerDayInput.value = 2;
    tradesPerDayVal.textContent = "2";
    checkRiskSafety();
    runSimulation();
  });

  // Tab switching
  tabFanBtn.addEventListener("click", () => switchTab("fan"));
  tabFirmsBtn.addEventListener("click", () => switchTab("firms"));
  tabGuideBtn.addEventListener("click", () => switchTab("guide"));
}

function switchTab(tabId) {
  [tabFanBtn, tabFirmsBtn, tabGuideBtn].forEach(b => {
    b.className = "tab-btn px-3.5 py-1.5 text-xs font-semibold rounded-lg text-slate-400 hover:text-white hover:bg-slate-800";
  });
  [tabFanContent, tabFirmsContent, tabGuideContent].forEach(c => c.classList.add("hidden"));

  if (tabId === "fan") {
    tabFanBtn.className = "tab-btn active px-3.5 py-1.5 text-xs font-semibold rounded-lg bg-indigo-600 text-white";
    tabFanContent.classList.remove("hidden");
  } else if (tabId === "firms") {
    tabFirmsBtn.className = "tab-btn active px-3.5 py-1.5 text-xs font-semibold rounded-lg bg-indigo-600 text-white";
    tabFirmsContent.classList.remove("hidden");
  } else if (tabId === "guide") {
    tabGuideBtn.className = "tab-btn active px-3.5 py-1.5 text-xs font-semibold rounded-lg bg-indigo-600 text-white";
    tabGuideContent.classList.remove("hidden");
  }
}

// Monte Carlo Client Simulation
function runSimulation() {
  const firm = PROP_FIRMS[currentFirmKey];
  const initialBalance = parseFloat(accountSizeSelect.value);
  const maxDays = parseInt(maxDaysSelect.value);
  const winRate = parseFloat(winRateInput.value) / 100.0;
  const rr = parseFloat(rewardRiskInput.value);
  const riskPct = parseFloat(riskPerTradeInput.value) / 100.0;
  const tradesPerDay = parseInt(tradesPerDayInput.value);

  const numPaths = 1500;
  let passedPaths = 0;
  let dailyBreaches = 0;
  let maxBreaches = 0;
  let daysArray = [];

  // Arrays to hold trajectories for percentiles
  const trajectories = new Float32Array(numPaths * (maxDays + 1));
  const samplePaths = [];

  for (let i = 0; i < numPaths; i++) {
    let balance = initialBalance;
    let highWaterMark = initialBalance;
    let phaseIdx = 0;
    let isActive = true;
    let daysSpent = 0;
    let phaseDays = 0;

    let targetAmt = initialBalance * (1.0 + firm.phases[phaseIdx].target / 100.0);
    let ddFloor = initialBalance * (1.0 - firm.maxDD / 100.0);

    trajectories[i * (maxDays + 1) + 0] = balance;

    for (let d = 1; d <= maxDays; d++) {
      if (!isActive) {
        trajectories[i * (maxDays + 1) + d] = balance;
        continue;
      }

      daysSpent++;
      phaseDays++;
      const startOfDayBalance = balance;
      const dailyLimit = firm.dailyDD > 0 ? startOfDayBalance * (firm.dailyDD / 100.0) : Infinity;

      let dayMinPnL = 0;
      let dayPnL = 0;
      let intradayEquity = balance;

      for (let t = 0; t < tradesPerDay; t++) {
        const isWin = Math.random() < winRate;
        const riskDollar = balance * riskPct;
        const pnl = isWin ? riskDollar * rr : -riskDollar;

        intradayEquity += pnl;
        dayPnL += pnl;
        if (dayPnL < dayMinPnL) dayMinPnL = dayPnL;

        // Trailing intraday peak check
        if (firm.ddType === "Trailing_Intraday") {
          if (intradayEquity > highWaterMark) {
            highWaterMark = intradayEquity;
            ddFloor = Math.max(ddFloor, highWaterMark * (1.0 - firm.maxDD / 100.0));
          }
          if (intradayEquity <= ddFloor) {
            isActive = false;
            maxBreaches++;
            balance = intradayEquity;
            break;
          }
        }
      }

      if (!isActive) {
        trajectories[i * (maxDays + 1) + d] = balance;
        continue;
      }

      // Daily limit check
      if (Math.abs(dayMinPnL) >= dailyLimit) {
        isActive = false;
        dailyBreaches++;
        balance += dayMinPnL;
        trajectories[i * (maxDays + 1) + d] = balance;
        continue;
      }

      balance += dayPnL;
      trajectories[i * (maxDays + 1) + d] = balance;

      // Trailing EOD or Relative
      if (firm.ddType === "Trailing_EOD" || firm.ddType === "Relative") {
        if (balance > highWaterMark) {
          highWaterMark = balance;
          let newFloor = highWaterMark * (1.0 - firm.maxDD / 100.0);
          if (firm.id === "topstep_combine" || firm.id === "e8_markets_classic") {
            newFloor = Math.min(initialBalance, newFloor);
          }
          ddFloor = Math.max(ddFloor, newFloor);
        }
      }

      // Max DD check
      if (balance <= ddFloor) {
        isActive = false;
        maxBreaches++;
        continue;
      }

      // Target check
      if (balance >= targetAmt && phaseDays >= firm.phases[phaseIdx].minDays) {
        phaseIdx++;
        if (phaseIdx >= firm.phases.length) {
          passedPaths++;
          daysArray.push(daysSpent);
          isActive = false;
          // Fill rest of trajectory with final balance
          for (let fillD = d + 1; fillD <= maxDays; fillD++) {
            trajectories[i * (maxDays + 1) + fillD] = balance;
          }
          break;
        } else {
          // Advance phase
          targetAmt = balance * (1.0 + firm.phases[phaseIdx].target / 100.0);
          if (firm.ddType === "Static") {
            ddFloor = balance * (1.0 - firm.maxDD / 100.0);
          }
          highWaterMark = balance;
          phaseDays = 0;
        }
      }
    }

    if (i < 8) {
      const singlePath = [];
      for (let d = 0; d <= maxDays; d++) {
        singlePath.push(trajectories[i * (maxDays + 1) + d]);
      }
      samplePaths.push(singlePath);
    }
  }

  // Calculate percentiles across days
  const p5 = [];
  const p25 = [];
  const p50 = [];
  const p75 = [];
  const p95 = [];

  for (let d = 0; d <= maxDays; d++) {
    const dayVals = new Float32Array(numPaths);
    for (let i = 0; i < numPaths; i++) {
      dayVals[i] = trajectories[i * (maxDays + 1) + d];
    }
    dayVals.sort();
    p5.push(dayVals[Math.floor(numPaths * 0.05)]);
    p25.push(dayVals[Math.floor(numPaths * 0.25)]);
    p50.push(dayVals[Math.floor(numPaths * 0.50)]);
    p75.push(dayVals[Math.floor(numPaths * 0.75)]);
    p95.push(dayVals[Math.floor(numPaths * 0.95)]);
  }

  // Update KPIs
  const passRate = (passedPaths / numPaths) * 100.0;
  const ruinRate = ((dailyBreaches + maxBreaches) / numPaths) * 100.0;
  const dailyBreachRate = (dailyBreaches / numPaths) * 100.0;
  const avgDays = daysArray.length > 0 ? (daysArray.reduce((a, b) => a + b, 0) / daysArray.length) : maxDays;
  const minRequiredDays = firm.phases.reduce((acc, p) => acc + p.minDays, 0);

  kpiPassRate.textContent = `${passRate.toFixed(1)}%`;
  kpiPassRate.className = `text-2xl font-black mt-1 ${passRate >= 75 ? 'text-emerald-400' : passRate >= 45 ? 'text-amber-400' : 'text-rose-400'}`;
  
  kpiRuinRate.textContent = `${ruinRate.toFixed(1)}%`;
  kpiRuinSub.textContent = `Daily: ${dailyBreachRate.toFixed(1)}% | Max: ${((maxBreaches / numPaths) * 100).toFixed(1)}%`;

  kpiAvgDays.textContent = `${avgDays.toFixed(1)} d`;
  kpiMinDays.textContent = `Min Required: ${minRequiredDays} days`;

  // Render Chart
  renderFanChart(maxDays, initialBalance, firm, p5, p25, p50, p75, p95, samplePaths);
}

// Render Chart.js Fan Chart
function renderFanChart(maxDays, initialBalance, firm, p5, p25, p50, p75, p95, samplePaths) {
  const ctx = document.getElementById("fanChartCanvas").getContext("2d");
  const labels = Array.from({ length: maxDays + 1 }, (_, i) => `Day ${i}`);

  const targetLine = Array(maxDays + 1).fill(initialBalance * (1.0 + firm.phases[0].target / 100.0));
  const maxDDLine = Array(maxDays + 1).fill(initialBalance * (1.0 - firm.maxDD / 100.0));

  if (currentChart) {
    currentChart.destroy();
  }

  const datasets = [
    {
      label: "Phase 1 Target",
      data: targetLine,
      borderColor: "#10b981",
      borderWidth: 1.5,
      borderDash: [5, 5],
      pointRadius: 0,
      fill: false,
    },
    {
      label: "Max Drawdown Barrier",
      data: maxDDLine,
      borderColor: "#ef4444",
      borderWidth: 1.5,
      borderDash: [5, 5],
      pointRadius: 0,
      fill: false,
    },
    {
      label: "Median Equity",
      data: p50,
      borderColor: "#6366f1",
      borderWidth: 2.2,
      pointRadius: 0,
      fill: false,
    },
    {
      label: "95th Percentile",
      data: p95,
      borderColor: "transparent",
      pointRadius: 0,
      fill: false,
    },
    {
      label: "5th Percentile",
      data: p5,
      borderColor: "transparent",
      backgroundColor: "rgba(99, 102, 241, 0.12)",
      pointRadius: 0,
      fill: "-1",
    },
  ];

  // Add a few sample individual trajectories
  samplePaths.forEach((path, idx) => {
    datasets.push({
      label: `Path ${idx + 1}`,
      data: path,
      borderColor: "rgba(148, 163, 184, 0.25)",
      borderWidth: 0.8,
      pointRadius: 0,
      fill: false,
    });
  });

  currentChart = new Chart(ctx, {
    type: "line",
    data: { labels, datasets },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      interaction: { mode: "index", intersect: false },
      plugins: {
        legend: { display: false },
        tooltip: {
          backgroundColor: "#0f172a",
          borderColor: "#334155",
          borderWidth: 1,
          callbacks: {
            label: (ctx) => `${ctx.dataset.label}: $${Math.round(ctx.parsed.y).toLocaleString()}`
          }
        }
      },
      scales: {
        x: {
          grid: { color: "rgba(51, 65, 85, 0.25)" },
          ticks: { color: "#94a3b8", maxTicksLimit: 12, font: { size: 10 } }
        },
        y: {
          grid: { color: "rgba(51, 65, 85, 0.25)" },
          ticks: {
            color: "#94a3b8",
            font: { size: 10 },
            callback: (val) => `$${Math.round(val / 1000)}k`
          }
        }
      }
    }
  });
}

// Auto Optimize Risk Sizing
function autoOptimizeRisk() {
  const firm = PROP_FIRMS[currentFirmKey];
  const candidates = [0.25, 0.50, 0.75, 1.0, 1.25, 1.5];
  
  // Choose safe optimal based on daily limit
  let bestRisk = 0.50;
  if (firm.dailyDD > 0) {
    bestRisk = Math.min(1.0, firm.dailyDD / 6.0);
    if (bestRisk < 0.25) bestRisk = 0.25;
  } else {
    bestRisk = Math.min(1.0, firm.maxDD / 8.0);
  }

  // Round to nearest 0.05
  bestRisk = Math.round(bestRisk * 20) / 20;

  riskPerTradeInput.value = bestRisk;
  riskPerTradeVal.textContent = `${bestRisk.toFixed(2)}%`;
  kpiOptimalRisk.textContent = `${bestRisk.toFixed(2)}%`;

  checkRiskSafety();
  runSimulation();
}

// Render 22 Prop Firms Comparison Table
function renderFirmsTable() {
  firmsTableBody.innerHTML = "";
  Object.keys(PROP_FIRMS).forEach(key => {
    const f = PROP_FIRMS[key];
    const tr = document.createElement("tr");
    tr.className = "hover:bg-slate-800/40 cursor-pointer transition-colors";
    tr.onclick = () => {
      firmSelect.value = f.id;
      currentFirmKey = f.id;
      updateFirmBadges();
      switchTab("fan");
      runSimulation();
    };

    const targetSum = f.phases.reduce((a, b) => a + b.target, 0);

    tr.innerHTML = `
      <td class="py-2.5 px-3 font-medium text-white flex items-center">
        <span class="w-1.5 h-1.5 rounded-full ${f.market === 'CME Futures' ? 'bg-amber-400' : 'bg-indigo-400'} mr-2"></span>
        ${f.name}
      </td>
      <td class="py-2.5 px-2 text-slate-400">${f.market}</td>
      <td class="py-2.5 px-2 text-slate-300 font-semibold">${f.phases.length}</td>
      <td class="py-2.5 px-2 text-emerald-400 font-bold">+${targetSum}%</td>
      <td class="py-2.5 px-2 text-amber-400">${f.dailyDD > 0 ? f.dailyDD + '%' : 'None'}</td>
      <td class="py-2.5 px-2 text-rose-400">-${f.maxDD}%</td>
      <td class="py-2.5 px-2 text-slate-300 font-mono text-[11px]">${f.ddType}</td>
      <td class="py-2.5 px-2 font-bold ${f.mdi > 2.2 ? 'text-rose-400' : 'text-emerald-400'}">${f.mdi.toFixed(2)}</td>
      <td class="py-2.5 px-2">
        <span class="inline-flex items-center px-2 py-0.5 rounded text-[11px] font-semibold bg-indigo-500/10 text-indigo-400 border border-indigo-500/20">
          Simulate
        </span>
      </td>
    `;
    firmsTableBody.appendChild(tr);
  });
}

// Kickoff
window.addEventListener("DOMContentLoaded", init);
