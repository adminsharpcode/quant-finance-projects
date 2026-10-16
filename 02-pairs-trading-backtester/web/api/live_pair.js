// Vercel Serverless Function: Live Market Data Fetcher for Pairs Trading
export default async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.setHeader('Cache-Control', 's-maxage=300, stale-while-revalidate=600');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  const { symbolX = 'XOM', symbolY = 'CVX', range = '2y' } = req.query;

  try {
    const fetchTicker = async (ticker) => {
      // Map common commodity aliases if needed
      let yfTicker = ticker.toUpperCase();
      if (yfTicker === 'WTI') yfTicker = 'CL=F';
      if (yfTicker === 'BRENT') yfTicker = 'BZ=F';
      if (yfTicker === 'GOLD') yfTicker = 'GC=F';
      if (yfTicker === 'SILVER') yfTicker = 'SI=F';
      if (yfTicker === 'BTC') yfTicker = 'BTC-USD';
      if (yfTicker === 'ETH') yfTicker = 'ETH-USD';

      const url = `https://query1.finance.yahoo.com/v8/finance/chart/${encodeURIComponent(yfTicker)}?interval=1d&range=${encodeURIComponent(range)}`;
      const response = await fetch(url, {
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
      });

      if (!response.ok) {
        throw new Error(`Yahoo Finance API error for ${ticker}: ${response.status} ${response.statusText}`);
      }

      const json = await response.json();
      const result = json?.chart?.result?.[0];
      if (!result) {
        throw new Error(`No chart data returned for ${ticker}`);
      }

      const timestamps = result.timestamp || [];
      const quotes = result.indicators?.quote?.[0] || {};
      const adjCloses = result.indicators?.adjclose?.[0]?.adjclose || quotes.close || [];

      const map = new Map();
      for (let i = 0; i < timestamps.length; i++) {
        const val = adjCloses[i] !== null && adjCloses[i] !== undefined ? adjCloses[i] : quotes.close?.[i];
        if (val !== null && val !== undefined && !isNaN(val)) {
          const dateStr = new Date(timestamps[i] * 1000).toISOString().split('T')[0];
          map.set(dateStr, Number(val.toFixed(2)));
        }
      }
      return map;
    };

    const [mapX, mapY] = await Promise.all([fetchTicker(symbolX), fetchTicker(symbolY)]);

    // Intersect common dates
    const commonDates = [];
    for (const d of mapX.keys()) {
      if (mapY.has(d)) commonDates.push(d);
    }
    commonDates.sort();

    if (commonDates.length < 20) {
      return res.status(400).json({
        ok: false,
        error: `Insufficient common trading bars (${commonDates.length}) found between ${symbolX} and ${symbolY}.`,
      });
    }

    const xSeries = commonDates.map((d) => mapX.get(d));
    const ySeries = commonDates.map((d) => mapY.get(d));

    const n = commonDates.length;
    const lastX = xSeries[n - 1];
    const lastY = ySeries[n - 1];
    const prevX = xSeries[n - 2] || lastX;
    const prevY = ySeries[n - 2] || lastY;

    const changeX = Number((((lastX - prevX) / prevX) * 100).toFixed(2));
    const changeY = Number((((lastY - prevY) / prevY) * 100).toFixed(2));

    return res.status(200).json({
      ok: true,
      symbolX: symbolX.toUpperCase(),
      symbolY: symbolY.toUpperCase(),
      dates: commonDates,
      x: xSeries,
      y: ySeries,
      lastPriceX: lastX,
      lastPriceY: lastY,
      changeX: changeX,
      changeY: changeY,
      source: 'Yahoo Finance Live V8 Engine',
      updatedAt: new Date().toISOString(),
    });
  } catch (err) {
    return res.status(500).json({
      ok: false,
      error: err.message || 'Internal error fetching live pair prices.',
    });
  }
}
