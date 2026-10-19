/**
 * LOBX | Limit Order Book & Avellaneda-Stoikov Market Making Engine
 * High-performance browser matching engine, dynamic depth ladder & microstructure telemetry.
 */

// ------------------- MATHEMATICAL CONSTANTS & APPLICATION STATE -------------------

const state = {
  activeAsset: "SPY",
  tickSize: 0.05,
  midPrice: 585.00,
  microPrice: 585.00,
  spread: 0.10,

  // Avellaneda-Stoikov Parameters
  gamma: 0.15,        // Risk aversion
  kappa: 12.0,        // Order flow liquidity intensity
  sigma: 0.030,       // Asset volatility
  qMax: 15,           // Maximum allowable inventory
  T: 60.0,            // Trading session horizon (seconds)
  asMode: "FINITE",   // "FINITE" or "STATIONARY"

  // Market Maker State
  mmInventory: 0,
  mmCash: 100000.0,
  mmRealizedPnl: 0.0,
  mmUnrealizedPnl: 0.0,
  mmVolume: 0,
  mmRoundtrips: 0,
  mmEntryPrice: 0.0,
  mmRebates: 0.0,
  mmOrderIds: new Set(),
  activeMmBid: null,
  activeMmAsk: null,
  pnlHistory: [],

  // PnL Attribution
  spreadCapture: 0.0,
  inventoryDrift: 0.0,
  adverseSelection: 0.0,

  // Microstructure Metrics
  ofi: 0.0,
  prevBidPrice: null,
  prevBidVol: 0,
  prevAskPrice: null,
  prevAskVol: 0,
  vpin: 0.20,
  bucketSize: 500,
  currentBucketVol: 0,
  currentBucketImbalance: 0,
  completedBuckets: [],

  // User Order Tracking
  userActiveOrder: null,
  userSide: "BUY",

  // Simulator Engine Status
  isEngineActive: true,
  engineTimerId: null,
  apiTimerId: null,
  orderSeq: 10000,
  tradeSeq: 1,

  // Assets benchmark catalog
  assets: {
    SPY: { symbol: "AMEX:SPY", name: "S&P 500 ETF", price: 585.50, tickSize: 0.05, vol: 0.030 },
    QQQ: { symbol: "NASDAQ:QQQ", name: "Invesco QQQ", price: 495.20, tickSize: 0.05, vol: 0.035 },
    NVDA: { symbol: "NASDAQ:NVDA", name: "NVIDIA Corp", price: 139.80, tickSize: 0.05, vol: 0.065 },
    AAPL: { symbol: "NASDAQ:AAPL", name: "Apple Inc.", price: 232.40, tickSize: 0.05, vol: 0.025 },
    BTC: { symbol: "BINANCE:BTCUSDT", name: "Bitcoin Spot", price: 68450.0, tickSize: 5.0, vol: 0.080 }
  }
};

// ------------------- IN-MEMORY HIGH-SPEED LIMIT ORDER BOOK -------------------

class BrowserLimitOrderBook {
  constructor(tickSize = 0.05) {
    this.tickSize = tickSize;
    this.bids = new Map(); // price -> Array of orders
    this.asks = new Map(); // price -> Array of orders
    this.ordersMap = new Map(); // orderId -> { side, price, order }
  }

  roundPrice(p) {
    return Math.round(p / this.tickSize) * this.tickSize;
  }

  getBestBid() {
    if (this.bids.size === 0) return null;
    return Math.max(...this.bids.keys());
  }

  getBestAsk() {
    if (this.asks.size === 0) return null;
    return Math.min(...this.asks.keys());
  }

  getLevelVolume(side, price) {
    const book = side === "BUY" ? this.bids : this.asks;
    const orders = book.get(price);
    if (!orders) return 0;
    return orders.reduce((acc, o) => acc + o.remainingQty, 0);
  }

  addLimitOrder(order) {
    order.price = this.roundPrice(order.price);
    const book = order.side === "BUY" ? this.bids : this.asks;

    if (!book.has(order.price)) {
      book.set(order.price, []);
    }
    book.get(order.price).push(order);
    this.ordersMap.set(order.orderId, { side: order.side, price: order.price, order });
  }

  cancelOrder(orderId) {
    const record = this.ordersMap.get(orderId);
    if (!record) return null;

    const book = record.side === "BUY" ? this.bids : this.asks;
    const orders = book.get(record.price);
    if (orders) {
      const idx = orders.findIndex(o => o.orderId === orderId);
      if (idx !== -1) {
        const removed = orders.splice(idx, 1)[0];
        if (orders.length === 0) {
          book.delete(record.price);
        }
        this.ordersMap.delete(orderId);
        return removed;
      }
    }
    return null;
  }

  getL2Snapshot(depth = 7) {
    const sortedBidPrices = Array.from(this.bids.keys()).sort((a, b) => b - a).slice(0, depth);
    const sortedAskPrices = Array.from(this.asks.keys()).sort((a, b) => a - b).slice(0, depth);

    const bids = sortedBidPrices.map(p => ({
      price: p,
      volume: this.getLevelVolume("BUY", p),
      orders: this.bids.get(p).length
    }));

    const asks = sortedAskPrices.map(p => ({
      price: p,
      volume: this.getLevelVolume("SELL", p),
      orders: this.asks.get(p).length
    }));

    return { bids, asks };
  }

  clear() {
    this.bids.clear();
    this.asks.clear();
    this.ordersMap.clear();
  }
}

const lob = new BrowserLimitOrderBook(state.tickSize);

// ------------------- FIFO MATCHING ENGINE & TRADE DISPATCHER -------------------

function matchOrder(takerOrder) {
  const trades = [];
  const isBuy = takerOrder.side === "BUY";

  while (takerOrder.remainingQty > 0) {
    const book = isBuy ? lob.asks : lob.bids;
    if (book.size === 0) break;

    const bestPrice = isBuy ? Math.min(...book.keys()) : Math.max(...book.keys());

    // Crossing boundary check for limit orders
    if (takerOrder.orderType === "LIMIT") {
      if (isBuy && bestPrice > takerOrder.price) break;
      if (!isBuy && bestPrice < takerOrder.price) break;
    }

    const levelOrders = book.get(bestPrice);
    if (!levelOrders || levelOrders.length === 0) {
      book.delete(bestPrice);
      continue;
    }

    while (levelOrders.length > 0 && takerOrder.remainingQty > 0) {
      const makerOrder = levelOrders[0];
      const matchQty = Math.min(takerOrder.remainingQty, makerOrder.remainingQty);

      makerOrder.remainingQty -= matchQty;
      takerOrder.remainingQty -= matchQty;

      const trade = {
        tradeId: state.tradeSeq++,
        timestamp: new Date().toTimeString().slice(0, 8),
        price: bestPrice,
        quantity: matchQty,
        makerOrderId: makerOrder.orderId,
        takerOrderId: takerOrder.orderId,
        takerSide: takerOrder.side,
        makerTraderId: makerOrder.traderId,
        takerTraderId: takerOrder.traderId
      };

      trades.push(trade);
      handleTradeExecution(trade);

      if (makerOrder.remainingQty === 0) {
        levelOrders.shift();
        lob.ordersMap.delete(makerOrder.orderId);
      }
    }

    if (levelOrders.length === 0) {
      book.delete(bestPrice);
    }
  }

  // If resting limit order remainder
  if (takerOrder.remainingQty > 0 && takerOrder.orderType === "LIMIT" && takerOrder.tif !== "IOC") {
    lob.addLimitOrder(takerOrder);
  }

  return trades;
}

// ------------------- AVELLANEDA-STOIKOV MATHEMATICAL KERNEL -------------------

function computeAvellanedaStoikov() {
  const s = state.midPrice;
  const q = state.mmInventory;
  const gamma = state.gamma;
  const sigma = state.sigma;
  const kappa = state.kappa;
  const T = state.T;
  const tickSize = state.tickSize;

  let r, halfSpread, bid, ask;

  if (state.asMode === "FINITE") {
    // Finite horizon: r(s, q, t) = s - q * gamma * sigma^2 * T
    r = s - (q * gamma * (sigma ** 2) * T);
    const totalSpread = (gamma * (sigma ** 2) * T) + (2.0 / gamma) * Math.log(1.0 + (gamma / kappa));
    halfSpread = Math.max(tickSize, totalSpread / 2.0);
    bid = r - halfSpread;
    ask = r + halfSpread;
  } else {
    // Guéant, Tapia, Manziadi (2012) Stationary approximation
    const c1 = (1.0 / gamma) * Math.log(1.0 + (gamma / kappa));
    const c2 = (gamma * (sigma ** 2)) / (2.0 * kappa * sigma * Math.sqrt(1.0 + (gamma / kappa)));
    const deltaAsk = c1 + (2 * q + 1) * c2;
    const deltaBid = c1 - (2 * q - 1) * c2;
    r = s - (q * gamma * (sigma ** 2) * 10);
    halfSpread = Math.max(tickSize, (deltaAsk + deltaBid) / 2.0);
    bid = s - Math.max(tickSize, deltaBid);
    ask = s + Math.max(tickSize, deltaAsk);
  }

  // Round to exchange tick increment
  bid = Math.floor(bid / tickSize) * tickSize;
  ask = Math.ceil(ask / tickSize) * tickSize;
  if (bid >= ask) ask = bid + tickSize;

  // Capacity boundaries
  const canBid = q < state.qMax;
  const canAsk = q > -state.qMax;

  return {
    reservationPrice: r,
    halfSpread: halfSpread,
    optBid: canBid ? bid : null,
    optAsk: canAsk ? ask : null,
    skewPenalty: -(q * gamma * (sigma ** 2) * T)
  };
}

function updateMarketMakerQuotes() {
  // Cancel previous MM quotes
  state.mmOrderIds.forEach(id => lob.cancelOrder(id));
  state.mmOrderIds.clear();

  const as = computeAvellanedaStoikov();
  state.activeMmBid = as.optBid;
  state.activeMmAsk = as.optAsk;

  if (as.optBid !== null) {
    const bidId = state.orderSeq++;
    state.mmOrderIds.add(bidId);
    lob.addLimitOrder({
      orderId: bidId,
      side: "BUY",
      price: as.optBid,
      quantity: 5,
      remainingQty: 5,
      orderType: "LIMIT",
      traderId: "AVELLANEDA_MM"
    });
  }

  if (as.optAsk !== null) {
    const askId = state.orderSeq++;
    state.mmOrderIds.add(askId);
    lob.addLimitOrder({
      orderId: askId,
      side: "SELL",
      price: as.optAsk,
      quantity: 5,
      remainingQty: 5,
      orderType: "LIMIT",
      traderId: "AVELLANEDA_MM"
    });
  }

  // Update diagnostic box elements
  const elR = document.getElementById("box-r-price");
  const elHalf = document.getElementById("box-half-spread");
  const elOptBid = document.getElementById("box-opt-bid");
  const elOptAsk = document.getElementById("box-opt-ask");
  const elSkew = document.getElementById("box-skew-penalty");

  if (elR) elR.textContent = `$${as.reservationPrice.toFixed(2)}`;
  if (elHalf) elHalf.textContent = `$${as.halfSpread.toFixed(3)} (${(as.halfSpread / state.tickSize).toFixed(1)} ticks)`;
  if (elOptBid) elOptBid.textContent = as.optBid ? `$${as.optBid.toFixed(2)}` : "PULLED (CAP)";
  if (elOptAsk) elOptAsk.textContent = as.optAsk ? `$${as.optAsk.toFixed(2)}` : "PULLED (CAP)";
  if (elSkew) elSkew.textContent = `${as.skewPenalty >= 0 ? "+$" : "-$"}${Math.abs(as.skewPenalty).toFixed(2)}`;
}

// ------------------- TRADE EXECUTION & PNL ATTRIBUTION ACCOUNTING -------------------

function handleTradeExecution(trade) {
  // Update VPIN
  updateVpin(trade);

  // Check if MM was involved
  const isMmOrder = state.mmOrderIds.has(trade.makerOrderId);
  if (isMmOrder) {
    const mmBought = (trade.takerSide === "SELL");
    const qty = trade.quantity;
    const price = trade.price;

    state.mmVolume += qty;
    const rebate = (0.20 * 1e-4) * (price * qty);
    state.mmRebates += rebate;

    // Spread capture attribution
    const spreadCaptured = Math.abs(price - state.midPrice) * qty;
    state.spreadCapture += spreadCaptured;

    if (mmBought) {
      state.mmCash -= (price * qty);
      if (state.mmInventory < 0) {
        const closedQty = Math.min(qty, Math.abs(state.mmInventory));
        state.mmRealizedPnl += closedQty * (state.mmEntryPrice - price);
        state.mmRoundtrips++;
        state.mmInventory += qty;
        if (state.mmInventory === 0) state.mmEntryPrice = 0.0;
        else if (state.mmInventory > 0) state.mmEntryPrice = price;
      } else {
        const prevNotional = state.mmInventory * state.mmEntryPrice;
        state.mmInventory += qty;
        state.mmEntryPrice = (prevNotional + price * qty) / state.mmInventory;
      }
    } else {
      state.mmCash += (price * qty);
      if (state.mmInventory > 0) {
        const closedQty = Math.min(qty, state.mmInventory);
        state.mmRealizedPnl += closedQty * (price - state.mmEntryPrice);
        state.mmRoundtrips++;
        state.mmInventory -= qty;
        if (state.mmInventory === 0) state.mmEntryPrice = 0.0;
        else if (state.mmInventory < 0) state.mmEntryPrice = price;
      } else {
        const prevNotional = Math.abs(state.mmInventory) * state.mmEntryPrice;
        state.mmInventory -= qty;
        state.mmEntryPrice = (prevNotional + price * qty) / Math.abs(state.mmInventory);
      }
    }
  }

  // Check if user order was executed
  if (state.userActiveOrder && trade.makerOrderId === state.userActiveOrder.orderId) {
    const banner = document.getElementById("order-feedback-banner");
    const desc = document.getElementById("feedback-desc");
    if (banner && desc) {
      banner.style.display = "block";
      desc.textContent = `Your resting ${state.userActiveOrder.side} order for ${trade.quantity} sh was filled @ $${trade.price.toFixed(2)} by ${trade.takerTraderId}!`;
      setTimeout(() => banner.style.display = "none", 4000);
    }
    state.userActiveOrder = null;
  }

  // Append to trade tape
  appendTradeTape(trade);
}

function updateVpin(trade) {
  state.currentBucketVol += trade.quantity;
  if (trade.takerSide === "BUY") {
    state.currentBucketImbalance += trade.quantity;
  } else {
    state.currentBucketImbalance -= trade.quantity;
  }

  if (state.currentBucketVol >= state.bucketSize) {
    const bucketImbalance = Math.abs(state.currentBucketImbalance);
    state.completedBuckets.push(bucketImbalance);
    if (state.completedBuckets.length > 20) state.completedBuckets.shift();

    const sumImb = state.completedBuckets.reduce((a, b) => a + b, 0);
    state.vpin = sumImb / (state.completedBuckets.length * state.bucketSize);
    state.currentBucketVol = 0;
    state.currentBucketImbalance = 0;
  }
}

function appendTradeTape(trade) {
  const container = document.getElementById("tape-container");
  if (!container) return;

  // Clear initial placeholder if present
  if (container.children.length === 1 && container.children[0].textContent.includes("Listening")) {
    container.innerHTML = "";
  }

  const row = document.createElement("div");
  row.className = "tape-row";
  const isBuy = trade.takerSide === "BUY";
  row.innerHTML = `
    <span style="color: var(--text-dim);">${trade.timestamp}</span>
    <span style="font-weight: 700;" class="${isBuy ? 'tape-buy' : 'tape-sell'}">${trade.takerSide}</span>
    <span style="font-weight: 800; color: #fff;">$${trade.price.toFixed(2)}</span>
    <span style="color: var(--accent-cyan); font-weight: 700;">${trade.quantity} sh</span>
    <span style="color: var(--text-dim); font-size: 0.68rem;">Maker: ${trade.makerTraderId.slice(0, 10)}</span>
  `;

  container.insertBefore(row, container.firstChild);
  if (container.children.length > 30) {
    container.removeChild(container.lastChild);
  }
}

// ------------------- UI DEPTH LADDER & TELEMETRY RENDERING -------------------

function renderDepthLadder() {
  const bestBid = lob.getBestBid();
  const bestAsk = lob.getBestAsk();

  if (bestBid !== null && bestAsk !== null) {
    const prevMid = state.midPrice;
    state.midPrice = roundTick((bestBid + bestAsk) / 2.0);
    state.spread = roundTick(bestAsk - bestBid);

    // Micro-price calculation
    const vb = lob.getLevelVolume("BUY", bestBid);
    const va = lob.getLevelVolume("SELL", bestAsk);
    state.microPrice = (vb + va) > 0 ? roundTick((vb * bestAsk + va * bestBid) / (vb + va)) : state.midPrice;

    // OFI Tracker
    updateOFI(bestBid, vb, bestAsk, va);

    // Inventory Drift Attribution
    state.inventoryDrift += state.mmInventory * (state.midPrice - prevMid);
  }

  // Update Telemetry Bar
  updateTelemetryUI();

  // Render Ladder Rows
  const snap = lob.getL2Snapshot(7);
  const asksContainer = document.getElementById("ladder-asks-container");
  const bidsContainer = document.getElementById("ladder-bids-container");

  if (!asksContainer || !bidsContainer) return;

  const maxVolume = Math.max(
    1,
    ...snap.bids.map(b => b.volume),
    ...snap.asks.map(a => a.volume)
  );

  // Render Asks descending (highest price down to best ask)
  asksContainer.innerHTML = "";
  const reversedAsks = [...snap.asks].reverse();
  reversedAsks.forEach(lvl => {
    const row = document.createElement("div");
    row.className = "ladder-row ladder-ask-row";
    const pct = Math.min(100, Math.round((lvl.volume / maxVolume) * 100));
    row.style.background = `linear-gradient(to left, rgba(244, 63, 94, 0.18) ${pct}%, transparent ${pct}%)`;

    const isMmQuote = state.activeMmAsk && Math.abs(lvl.price - state.activeMmAsk) < 1e-4;
    const isUserOrder = state.userActiveOrder && state.userActiveOrder.side === "SELL" && Math.abs(lvl.price - state.userActiveOrder.price) < 1e-4;

    row.innerHTML = `
      <span style="color: var(--text-dim); text-align: right;"></span>
      <span></span>
      <span></span>
      <span style="font-weight: 800; color: var(--accent-red);">$${lvl.price.toFixed(2)}</span>
      <span style="font-weight: 700; color: #fff;">${lvl.volume}</span>
      <span style="color: var(--text-dim); text-align: right;">${lvl.orders}</span>
      ${isMmQuote ? '<span class="ladder-tag-mm tag-mm-ask">MM ASK* →</span>' : ''}
      ${isUserOrder ? '<span class="ladder-tag-mm tag-user-order" style="left: 10px;">★ YOU</span>' : ''}
    `;
    asksContainer.appendChild(row);
  });

  // Render Bids descending (best bid down to lowest bid)
  bidsContainer.innerHTML = "";
  snap.bids.forEach(lvl => {
    const row = document.createElement("div");
    row.className = "ladder-row ladder-bid-row";
    const pct = Math.min(100, Math.round((lvl.volume / maxVolume) * 100));
    row.style.background = `linear-gradient(to right, rgba(16, 185, 129, 0.18) ${pct}%, transparent ${pct}%)`;

    const isMmQuote = state.activeMmBid && Math.abs(lvl.price - state.activeMmBid) < 1e-4;
    const isUserOrder = state.userActiveOrder && state.userActiveOrder.side === "BUY" && Math.abs(lvl.price - state.userActiveOrder.price) < 1e-4;

    row.innerHTML = `
      <span style="color: var(--text-dim); text-align: right;">${lvl.orders}</span>
      <span style="font-weight: 700; color: #fff; text-align: right;">${lvl.volume}</span>
      <span style="font-weight: 800; color: var(--accent-green); text-align: right;">$${lvl.price.toFixed(2)}</span>
      <span></span>
      <span></span>
      <span></span>
      ${isMmQuote ? '<span class="ladder-tag-mm tag-mm-bid" style="left: 10px;">← MM BID*</span>' : ''}
      ${isUserOrder ? '<span class="ladder-tag-mm tag-user-order" style="right: 10px;">★ YOU</span>' : ''}
    `;
    bidsContainer.appendChild(row);
  });

  // Update Ladder Separator Bar
  const elLadderMid = document.getElementById("ladder-mid-val");
  const elLadderSpread = document.getElementById("ladder-spread-val");
  const elLadderMicro = document.getElementById("ladder-micro-val");
  if (elLadderMid) elLadderMid.textContent = `$${state.midPrice.toFixed(2)}`;
  if (elLadderSpread) elLadderSpread.textContent = `$${state.spread.toFixed(2)}`;
  if (elLadderMicro) elLadderMicro.textContent = `$${state.microPrice.toFixed(2)}`;
}

function updateOFI(bestBid, bidVol, bestAsk, askVol) {
  if (state.prevBidPrice !== null && state.prevAskPrice !== null) {
    let deltaBid = 0;
    if (bestBid > state.prevBidPrice) deltaBid = bidVol;
    else if (bestBid === state.prevBidPrice) deltaBid = bidVol - state.prevBidVol;
    else deltaBid = -state.prevBidVol;

    let deltaAsk = 0;
    if (bestAsk < state.prevAskPrice) deltaAsk = askVol;
    else if (bestAsk === state.prevAskPrice) deltaAsk = askVol - state.prevAskVol;
    else deltaAsk = -state.prevAskVol;

    state.ofi = deltaBid - deltaAsk;
  }

  state.prevBidPrice = bestBid;
  state.prevBidVol = bidVol;
  state.prevAskPrice = bestAsk;
  state.prevAskVol = askVol;
}

function updateTelemetryUI() {
  const elMid = document.getElementById("tele-mid");
  const elMicro = document.getElementById("tele-micro");
  const elImb = document.getElementById("tele-imbalance");
  const elSpread = document.getElementById("tele-spread");
  const elSpreadBps = document.getElementById("tele-spread-bps");
  const elOfi = document.getElementById("tele-ofi");
  const elVpin = document.getElementById("tele-vpin");
  const elVpinPill = document.getElementById("vpin-status-pill");
  const elInv = document.getElementById("tele-inventory");
  const elResPrice = document.getElementById("tele-res-price");
  const elPnl = document.getElementById("tele-pnl");
  const elRealized = document.getElementById("tele-realized");
  const elUnrealized = document.getElementById("tele-unrealized");
  const elSharpe = document.getElementById("tele-sharpe");

  // Mark MM to market
  if (state.mmInventory > 0) {
    state.mmUnrealizedPnl = state.mmInventory * (state.midPrice - state.mmEntryPrice);
  } else if (state.mmInventory < 0) {
    state.mmUnrealizedPnl = Math.abs(state.mmInventory) * (state.mmEntryPrice - state.midPrice);
  } else {
    state.mmUnrealizedPnl = 0.0;
  }

  const totalPnl = state.mmRealizedPnl + state.mmUnrealizedPnl + state.mmRebates;
  state.pnlHistory.push(totalPnl);
  if (state.pnlHistory.length > 50) state.pnlHistory.shift();

  if (elMid) elMid.textContent = `$${state.midPrice.toFixed(2)}`;
  if (elMicro) elMicro.textContent = `$${state.microPrice.toFixed(2)}`;

  const spreadBps = ((state.spread / state.midPrice) * 10000).toFixed(1);
  if (elSpread) elSpread.textContent = `$${state.spread.toFixed(2)}`;
  if (elSpreadBps) elSpreadBps.textContent = `${spreadBps} bps`;

  if (elOfi) {
    elOfi.textContent = `${state.ofi >= 0 ? "+" : ""}${state.ofi.toFixed(0)} sh`;
    elOfi.style.color = state.ofi >= 0 ? "var(--accent-cyan)" : "var(--accent-red)";
  }

  if (elVpin) {
    elVpin.textContent = state.vpin.toFixed(3);
    const isToxic = state.vpin > 0.45;
    elVpin.style.color = isToxic ? "var(--accent-red)" : "var(--accent-green)";
    if (elVpinPill) {
      elVpinPill.textContent = isToxic ? "⚠️ HIGH TOXICITY" : "BALANCED";
      elVpinPill.style.color = isToxic ? "var(--accent-red)" : "var(--accent-green)";
    }
  }

  if (elInv) {
    elInv.textContent = `${state.mmInventory} sh`;
    elInv.style.color = state.mmInventory === 0 ? "#fff" : state.mmInventory > 0 ? "var(--accent-cyan)" : "var(--accent-amber)";
  }

  const as = computeAvellanedaStoikov();
  if (elResPrice) elResPrice.textContent = `$${as.reservationPrice.toFixed(2)}`;

  if (elPnl) {
    elPnl.textContent = `${totalPnl >= 0 ? "+$" : "-$"}${Math.abs(totalPnl).toFixed(2)}`;
    elPnl.style.color = totalPnl >= 0 ? "var(--accent-green)" : "var(--accent-red)";
  }

  if (elRealized) elRealized.textContent = `${state.mmRealizedPnl >= 0 ? "+$" : "-$"}${Math.abs(state.mmRealizedPnl).toFixed(2)}`;
  if (elUnrealized) elUnrealized.textContent = `${state.mmUnrealizedPnl >= 0 ? "+$" : "-$"}${Math.abs(state.mmUnrealizedPnl).toFixed(2)}`;

  // Attribution Grid
  const elAttSpread = document.getElementById("att-spread");
  const elAttDrift = document.getElementById("att-drift");
  const elAttAdverse = document.getElementById("att-adverse");
  const elAttRebates = document.getElementById("att-rebates");

  if (elAttSpread) elAttSpread.textContent = `+$${state.spreadCapture.toFixed(2)}`;
  if (elAttDrift) elAttDrift.textContent = `${state.inventoryDrift >= 0 ? "+$" : "-$"}${Math.abs(state.inventoryDrift).toFixed(2)}`;
  if (elAttAdverse) elAttAdverse.textContent = `-$${state.adverseSelection.toFixed(2)}`;
  if (elAttRebates) elAttRebates.textContent = `+$${state.mmRebates.toFixed(2)}`;
}

function roundTick(p) {
  return Math.round(p / state.tickSize) * state.tickSize;
}

// ------------------- SIMULATOR STOCHASTIC POISSON BACKGROUND LOOP -------------------

function seedBookLiquidity() {
  lob.clear();
  const mid = state.midPrice;
  const tick = state.tickSize;

  for (let i = 1; i <= 8; i++) {
    const bidP = roundTick(mid - i * tick);
    const askP = roundTick(mid + i * tick);
    lob.addLimitOrder({
      orderId: state.orderSeq++,
      side: "BUY",
      price: bidP,
      quantity: 15 + Math.floor(Math.random() * 50),
      remainingQty: 15 + Math.floor(Math.random() * 50),
      orderType: "LIMIT",
      traderId: "RETAIL_BID"
    });
    lob.addLimitOrder({
      orderId: state.orderSeq++,
      side: "SELL",
      price: askP,
      quantity: 15 + Math.floor(Math.random() * 50),
      remainingQty: 15 + Math.floor(Math.random() * 50),
      orderType: "LIMIT",
      traderId: "RETAIL_ASK"
    });
  }

  updateMarketMakerQuotes();
  renderDepthLadder();
}

function executePoissonEvent() {
  if (!state.isEngineActive) return;

  const roll = Math.random();
  const side = Math.random() < 0.5 ? "BUY" : "SELL";
  const qty = 1 + Math.floor(Math.random() * 8);

  if (roll < 0.35) {
    // Aggressive market order sweep
    const taker = {
      orderId: state.orderSeq++,
      side: side,
      price: 0.0,
      quantity: qty,
      remainingQty: qty,
      orderType: "MARKET",
      traderId: "TAKER_SWEEP"
    };
    matchOrder(taker);
  } else if (roll < 0.50) {
    // Order cancellation
    const targetMap = side === "BUY" ? lob.bids : lob.asks;
    if (targetMap.size > 2) {
      const keys = Array.from(targetMap.keys());
      const randomPrice = keys[Math.floor(Math.random() * keys.length)];
      const orders = targetMap.get(randomPrice);
      if (orders && orders.length > 0) {
        // Do not cancel market maker quotes
        const nonMm = orders.find(o => !state.mmOrderIds.has(o.orderId) && (!state.userActiveOrder || o.orderId !== state.userActiveOrder.orderId));
        if (nonMm) {
          lob.cancelOrder(nonMm.orderId);
        }
      }
    }
  } else {
    // Passive limit order injection
    const offset = (1 + Math.floor(Math.random() * 4)) * state.tickSize;
    const price = side === "BUY" ? roundTick(state.midPrice - offset) : roundTick(state.midPrice + offset);
    lob.addLimitOrder({
      orderId: state.orderSeq++,
      side: side,
      price: price,
      quantity: qty,
      remainingQty: qty,
      orderType: "LIMIT",
      traderId: "RETAIL_LIMIT"
    });
  }

  // Refresh market maker optimal quotes and update depth ladder
  updateMarketMakerQuotes();
  renderDepthLadder();
}

// ------------------- LIVE MARKET DATA API SYNC -------------------

async function fetchLiveExchangeQuotes() {
  try {
    const res = await fetch("/api/quotes", { cache: "no-store" });
    if (res.ok) {
      const data = await res.json();
      if (data.status === "ok" && data.quotes && data.quotes[state.activeAsset]) {
        const q = data.quotes[state.activeAsset];
        const prevPrice = state.midPrice;
        if (Math.abs(q.price - prevPrice) > (state.tickSize * 2)) {
          state.midPrice = roundTick(q.price);
          seedBookLiquidity();
        }
      }
    }
  } catch (err) {
    // Fallback to local stochastic generation
  }
}

// ------------------- TRADINGVIEW TERMINAL EMBED ENGINE -------------------

function updateTradingViewWidget(symbol) {
  const container = document.getElementById("tv-widget-container");
  if (!container) return;

  const settings = {
    autosize: true,
    symbol: symbol,
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

  let iframe = document.getElementById("tradingview_active_iframe");
  if (iframe) {
    if (iframe.src !== targetUrl) iframe.src = targetUrl;
  } else {
    container.innerHTML = "";
    iframe = document.createElement("iframe");
    iframe.id = "tradingview_active_iframe";
    iframe.title = "TradingView Real-Time Chart";
    iframe.src = targetUrl;
    iframe.style.width = "100%";
    iframe.style.height = "100%";
    iframe.style.border = "none";
    iframe.allowFullscreen = true;
    container.appendChild(iframe);
  }
}

// ------------------- EVENT LISTENERS & USER CONTROLS BINDING -------------------

function initEventListeners() {
  // 1. TradingView Tab Switcher
  const tvTabs = [
    { id: "tv-tab-spy", asset: "SPY", symbol: "AMEX:SPY" },
    { id: "tv-tab-qqq", asset: "QQQ", symbol: "NASDAQ:QQQ" },
    { id: "tv-tab-nvda", asset: "NVDA", symbol: "NASDAQ:NVDA" },
    { id: "tv-tab-aapl", asset: "AAPL", symbol: "NASDAQ:AAPL" },
    { id: "tv-tab-btc", asset: "BTC", symbol: "BINANCE:BTCUSDT" }
  ];

  tvTabs.forEach(tab => {
    const btn = document.getElementById(tab.id);
    if (!btn) return;
    btn.addEventListener("click", () => {
      tvTabs.forEach(t => document.getElementById(t.id)?.classList.remove("active"));
      btn.classList.add("active");

      state.activeAsset = tab.asset;
      const assetInfo = state.assets[tab.asset];
      state.midPrice = roundTick(assetInfo.price);
      state.tickSize = assetInfo.tickSize;
      state.sigma = assetInfo.vol;

      const sliderSigma = document.getElementById("slider-sigma");
      const valSigma = document.getElementById("val-sigma");
      if (sliderSigma) sliderSigma.value = state.sigma;
      if (valSigma) valSigma.textContent = state.sigma.toFixed(3);

      updateTradingViewWidget(tab.symbol);
      seedBookLiquidity();
    });
  });

  // 2. Stream Toggle Button
  const btnToggle = document.getElementById("btn-stream-toggle");
  const toggleText = document.getElementById("stream-btn-text");
  if (btnToggle) {
    btnToggle.addEventListener("click", () => {
      state.isEngineActive = !state.isEngineActive;
      btnToggle.classList.toggle("paused", !state.isEngineActive);
      if (toggleText) {
        toggleText.textContent = state.isEngineActive ? "MATCHING ENGINE: ACTIVE" : "MATCHING ENGINE: PAUSED";
      }
    });
  }

  // 3. Avellaneda Controls Sliders
  const sliderGamma = document.getElementById("slider-gamma");
  const valGamma = document.getElementById("val-gamma");
  if (sliderGamma) {
    sliderGamma.addEventListener("input", (e) => {
      state.gamma = parseFloat(e.target.value);
      if (valGamma) valGamma.textContent = state.gamma.toFixed(2);
      updateMarketMakerQuotes();
      renderDepthLadder();
    });
  }

  const sliderKappa = document.getElementById("slider-kappa");
  const valKappa = document.getElementById("val-kappa");
  if (sliderKappa) {
    sliderKappa.addEventListener("input", (e) => {
      state.kappa = parseFloat(e.target.value);
      if (valKappa) valKappa.textContent = state.kappa.toFixed(1);
      updateMarketMakerQuotes();
      renderDepthLadder();
    });
  }

  const sliderSigma = document.getElementById("slider-sigma");
  const valSigma = document.getElementById("val-sigma");
  if (sliderSigma) {
    sliderSigma.addEventListener("input", (e) => {
      state.sigma = parseFloat(e.target.value);
      if (valSigma) valSigma.textContent = state.sigma.toFixed(3);
      updateMarketMakerQuotes();
      renderDepthLadder();
    });
  }

  const sliderQmax = document.getElementById("slider-qmax");
  const valQmax = document.getElementById("val-qmax");
  if (sliderQmax) {
    sliderQmax.addEventListener("input", (e) => {
      state.qMax = parseInt(e.target.value, 10);
      if (valQmax) valQmax.textContent = `${state.qMax} sh`;
      updateMarketMakerQuotes();
      renderDepthLadder();
    });
  }

  const selectAsMode = document.getElementById("select-as-mode");
  if (selectAsMode) {
    selectAsMode.addEventListener("change", (e) => {
      state.asMode = e.target.value;
      updateMarketMakerQuotes();
      renderDepthLadder();
    });
  }

  // 4. Order Entry Side Toggle (BUY / SELL)
  const btnBuy = document.getElementById("btn-side-buy");
  const btnSell = document.getElementById("btn-side-sell");
  if (btnBuy && btnSell) {
    btnBuy.addEventListener("click", () => {
      btnBuy.classList.add("active-buy");
      btnSell.classList.remove("active-sell");
      state.userSide = "BUY";
    });
    btnSell.addEventListener("click", () => {
      btnSell.classList.add("active-sell");
      btnBuy.classList.remove("active-buy");
      state.userSide = "SELL";
    });
  }

  // Peg Buttons
  const btnPegBid = document.getElementById("btn-peg-bid");
  const btnPegAsk = document.getElementById("btn-peg-ask");
  const inputPrice = document.getElementById("user-order-price");
  if (btnPegBid && inputPrice) {
    btnPegBid.addEventListener("click", () => {
      const bb = lob.getBestBid();
      if (bb) inputPrice.value = bb.toFixed(2);
    });
  }
  if (btnPegAsk && inputPrice) {
    btnPegAsk.addEventListener("click", () => {
      const ba = lob.getBestAsk();
      if (ba) inputPrice.value = ba.toFixed(2);
    });
  }

  // Order Type Change (Limit vs Market)
  const selectOrderType = document.getElementById("user-order-type");
  const groupUserPrice = document.getElementById("group-user-price");
  if (selectOrderType && groupUserPrice) {
    selectOrderType.addEventListener("change", (e) => {
      groupUserPrice.style.display = e.target.value === "MARKET" ? "none" : "flex";
    });
  }

  // Submit Order Execution Button
  const btnSubmit = document.getElementById("btn-submit-order");
  if (btnSubmit) {
    btnSubmit.addEventListener("click", () => {
      const ordType = selectOrderType ? selectOrderType.value : "LIMIT";
      const side = state.userSide;
      const qty = parseInt(document.getElementById("user-order-qty")?.value || "10", 10);
      const price = parseFloat(document.getElementById("user-order-price")?.value || state.midPrice.toString());
      const tif = document.getElementById("user-order-tif")?.value || "GTC";

      const userOrder = {
        orderId: state.orderSeq++,
        side: side,
        price: roundTick(price),
        quantity: qty,
        remainingQty: qty,
        orderType: ordType,
        tif: tif,
        traderId: "YOU_PORTFOLIO"
      };

      if (ordType === "LIMIT") {
        state.userActiveOrder = userOrder;
      }

      const trades = matchOrder(userOrder);

      // Feedback display
      const banner = document.getElementById("order-feedback-banner");
      const title = document.getElementById("feedback-title");
      const desc = document.getElementById("feedback-desc");

      if (banner && title && desc) {
        banner.style.display = "block";
        if (trades.length > 0) {
          const totalExecQty = trades.reduce((acc, t) => acc + t.quantity, 0);
          const avgP = trades.reduce((acc, t) => acc + t.price * t.quantity, 0) / totalExecQty;
          title.textContent = `⚡ ORDER FILLED (${totalExecQty}/${qty} sh)`;
          title.style.color = "var(--accent-green)";
          desc.textContent = `Executed ${side} ${totalExecQty} sh @ avg $${avgP.toFixed(2)}. ${userOrder.remainingQty > 0 ? `${userOrder.remainingQty} sh resting in queue.` : 'Full fill.'}`;
        } else {
          title.textContent = `📋 LIMIT ORDER QUEUED`;
          title.style.color = "var(--accent-cyan)";
          desc.textContent = `Placed ${side} ${qty} sh @ $${price.toFixed(2)} in book. Queue position active.`;
        }
        setTimeout(() => banner.style.display = "none", 4500);
      }

      updateMarketMakerQuotes();
      renderDepthLadder();
    });
  }
}

// ------------------- APPLICATION INITIALIZATION -------------------

function init() {
  seedBookLiquidity();
  initEventListeners();

  // 1. Continuous Poisson order matching engine loop (every 750ms)
  state.engineTimerId = setInterval(executePoissonEvent, 750);

  // 2. Poll serverless live market quotes API every 4s
  fetchLiveExchangeQuotes();
  state.apiTimerId = setInterval(fetchLiveExchangeQuotes, 4000);
}

window.addEventListener("DOMContentLoaded", init);
