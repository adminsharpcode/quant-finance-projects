export default async function handler(req, res) {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "GET, OPTIONS");
  res.setHeader("Cache-Control", "s-maxage=2, stale-while-revalidate=5");

  if (req.method === "OPTIONS") {
    return res.status(200).end();
  }

  let quotes = {
    SPY: {
      symbol: "AMEX:SPY",
      name: "SPDR S&P 500 ETF",
      price: 585.50,
      open: 582.00,
      high: 588.20,
      low: 581.40,
      changePct: 0.60,
      bid: 585.45,
      ask: 585.55,
      vol: 0.142,
      tickSize: 0.05,
      source: "CBOE / NYSE Arca",
    },
    QQQ: {
      symbol: "NASDAQ:QQQ",
      name: "Invesco QQQ Trust",
      price: 495.20,
      open: 491.50,
      high: 497.80,
      low: 490.80,
      changePct: 0.75,
      bid: 495.15,
      ask: 495.25,
      vol: 0.185,
      tickSize: 0.05,
      source: "NASDAQ Real-Time",
    },
    NVDA: {
      symbol: "NASDAQ:NVDA",
      name: "NVIDIA Corporation",
      price: 139.80,
      open: 136.50,
      high: 142.00,
      low: 135.80,
      changePct: 2.41,
      bid: 139.75,
      ask: 139.85,
      vol: 0.465,
      tickSize: 0.05,
      source: "NASDAQ Level 2",
    },
    AAPL: {
      symbol: "NASDAQ:AAPL",
      name: "Apple Inc.",
      price: 232.40,
      open: 230.10,
      high: 234.00,
      low: 229.80,
      changePct: 1.00,
      bid: 232.35,
      ask: 232.45,
      vol: 0.210,
      tickSize: 0.05,
      source: "NASDAQ Level 2",
    },
    BTC: {
      symbol: "BINANCE:BTCUSDT",
      name: "Bitcoin Spot",
      price: 68450.0,
      open: 67200.0,
      high: 69100.0,
      low: 66900.0,
      changePct: 1.86,
      bid: 68445.0,
      ask: 68455.0,
      vol: 0.540,
      tickSize: 5.0,
      source: "Binance Spot Real-Time",
    }
  };

  try {
    const [spyRes, qqqRes, nvdaRes, aaplRes, btcRes] = await Promise.allSettled([
      fetch("https://query1.finance.yahoo.com/v8/finance/chart/SPY", {
        headers: { "User-Agent": "Mozilla/5.0" },
      }).then((r) => r.json()),
      fetch("https://query1.finance.yahoo.com/v8/finance/chart/QQQ", {
        headers: { "User-Agent": "Mozilla/5.0" },
      }).then((r) => r.json()),
      fetch("https://query1.finance.yahoo.com/v8/finance/chart/NVDA", {
        headers: { "User-Agent": "Mozilla/5.0" },
      }).then((r) => r.json()),
      fetch("https://query1.finance.yahoo.com/v8/finance/chart/AAPL", {
        headers: { "User-Agent": "Mozilla/5.0" },
      }).then((r) => r.json()),
      fetch("https://api.binance.com/api/v3/ticker/24hr?symbol=BTCUSDT", {
        headers: { "User-Agent": "LOB-Simulator/1.0" },
      }).then((r) => r.json()),
    ]);

    // Parse SPY
    if (spyRes.status === "fulfilled" && spyRes.value?.chart?.result?.[0]?.meta) {
      const meta = spyRes.value.chart.result[0].meta;
      const p = parseFloat(meta.regularMarketPrice);
      if (!isNaN(p) && p > 100 && p < 2000) {
        const prevClose = parseFloat(meta.chartPreviousClose) || p;
        const chg = ((p - prevClose) / prevClose) * 100;
        quotes.SPY.price = Math.round(p * 100) / 100;
        quotes.SPY.open = Math.round(prevClose * 100) / 100;
        quotes.SPY.bid = Math.round((p - 0.05) * 100) / 100;
        quotes.SPY.ask = Math.round((p + 0.05) * 100) / 100;
        quotes.SPY.changePct = Math.round(chg * 100) / 100;
      }
    }

    // Parse QQQ
    if (qqqRes.status === "fulfilled" && qqqRes.value?.chart?.result?.[0]?.meta) {
      const meta = qqqRes.value.chart.result[0].meta;
      const p = parseFloat(meta.regularMarketPrice);
      if (!isNaN(p) && p > 100 && p < 2000) {
        const prevClose = parseFloat(meta.chartPreviousClose) || p;
        const chg = ((p - prevClose) / prevClose) * 100;
        quotes.QQQ.price = Math.round(p * 100) / 100;
        quotes.QQQ.open = Math.round(prevClose * 100) / 100;
        quotes.QQQ.bid = Math.round((p - 0.05) * 100) / 100;
        quotes.QQQ.ask = Math.round((p + 0.05) * 100) / 100;
        quotes.QQQ.changePct = Math.round(chg * 100) / 100;
      }
    }

    // Parse NVDA
    if (nvdaRes.status === "fulfilled" && nvdaRes.value?.chart?.result?.[0]?.meta) {
      const meta = nvdaRes.value.chart.result[0].meta;
      const p = parseFloat(meta.regularMarketPrice);
      if (!isNaN(p) && p > 10 && p < 1000) {
        const prevClose = parseFloat(meta.chartPreviousClose) || p;
        const chg = ((p - prevClose) / prevClose) * 100;
        quotes.NVDA.price = Math.round(p * 100) / 100;
        quotes.NVDA.open = Math.round(prevClose * 100) / 100;
        quotes.NVDA.bid = Math.round((p - 0.05) * 100) / 100;
        quotes.NVDA.ask = Math.round((p + 0.05) * 100) / 100;
        quotes.NVDA.changePct = Math.round(chg * 100) / 100;
      }
    }

    // Parse AAPL
    if (aaplRes.status === "fulfilled" && aaplRes.value?.chart?.result?.[0]?.meta) {
      const meta = aaplRes.value.chart.result[0].meta;
      const p = parseFloat(meta.regularMarketPrice);
      if (!isNaN(p) && p > 50 && p < 1000) {
        const prevClose = parseFloat(meta.chartPreviousClose) || p;
        const chg = ((p - prevClose) / prevClose) * 100;
        quotes.AAPL.price = Math.round(p * 100) / 100;
        quotes.AAPL.open = Math.round(prevClose * 100) / 100;
        quotes.AAPL.bid = Math.round((p - 0.05) * 100) / 100;
        quotes.AAPL.ask = Math.round((p + 0.05) * 100) / 100;
        quotes.AAPL.changePct = Math.round(chg * 100) / 100;
      }
    }

    // Parse BTCUSDT
    if (btcRes.status === "fulfilled" && btcRes.value && btcRes.value.lastPrice) {
      const b = btcRes.value;
      const p = parseFloat(b.lastPrice);
      if (!isNaN(p) && p > 10000 && p < 250000) {
        const open = parseFloat(b.openPrice) || p * 0.99;
        const chg = parseFloat(b.priceChangePercent) || ((p - open) / open) * 100;
        quotes.BTC.price = Math.round(p * 100) / 100;
        quotes.BTC.open = Math.round(open * 100) / 100;
        quotes.BTC.bid = Math.round((p - 5.0) * 100) / 100;
        quotes.BTC.ask = Math.round((p + 5.0) * 100) / 100;
        quotes.BTC.changePct = Math.round(chg * 100) / 100;
      }
    }
  } catch (err) {
    // Fallback to defaults
  }

  return res.status(200).json({
    status: "ok",
    timestamp: Date.now(),
    quotes: quotes,
  });
}
