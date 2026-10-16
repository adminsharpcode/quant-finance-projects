"""Dynamic State-Space Kalman Filter for Time-Varying Hedge Ratio & Intercept Tracking.

Replaces static OLS regression with an adaptive linear quadratic estimator that
continuously tracks structural shifts in alpha and market beta between asset pairs.
"""

from dataclasses import dataclass
from typing import Optional, Tuple
import numpy as np
import pandas as pd


@dataclass
class KalmanFilterResult:
    """Container for state-space Kalman filter time series outputs."""
    alpha_history: np.ndarray        # Estimated dynamic intercept alpha_t
    beta_history: np.ndarray         # Estimated dynamic hedge ratio beta_t
    spread_history: np.ndarray       # Prediction innovation e_t = y_t - (alpha_t-1 + beta_t-1 * x_t)
    spread_std_history: np.ndarray   # Innovation standard deviation sqrt(S_t)
    zscore_history: np.ndarray       # Standardized z-score e_t / sqrt(S_t)
    kalman_gains: np.ndarray         # Optimal gain vectors K_t over time
    covariance_history: np.ndarray   # Posterior state covariance matrices P_t


class KalmanHedgeTracker:
    """Two-dimensional linear state-space Kalman Filter tracking dynamic hedge ratios.

    State Vector:
        theta_t = [alpha_t, beta_t]^T
    Transition Model:
        theta_t = theta_{t-1} + w_t,  w_t ~ N(0, Q)
    Measurement Model:
        y_t = [1, x_t] * theta_t + v_t,  v_t ~ N(0, R)
    """

    def __init__(
        self,
        delta: float = 1e-4,
        r_var: float = 1e-3,
        initial_alpha: float = 0.0,
        initial_beta: float = 1.0,
        initial_p_var: float = 1.0
    ):
        """Initialize the Kalman filter parameters.

        Args:
            delta: Process noise tuning scalar. Covariance Q = (delta / (1 - delta)) * I.
                   Controls the responsiveness of beta to price adjustments.
            r_var: Measurement noise variance R. Controls tolerance for microstructural noise.
            initial_alpha: Prior guess for intercept alpha_0.
            initial_beta: Prior guess for hedge ratio beta_0.
            initial_p_var: Prior variance for state covariance matrix P_0.
        """
        self.delta = delta
        self.r_var = r_var

        # State vector: [alpha, beta]
        self.theta = np.array([initial_alpha, initial_beta], dtype=float)

        # State error covariance P
        self.p_matrix = np.eye(2, dtype=float) * initial_p_var

        # Process noise covariance Q
        # Using adaptive formulation Q = (delta / (1 - delta)) * I
        q_rate = self.delta / (1.0 - self.delta) if self.delta < 1.0 else self.delta
        self.q_matrix = np.eye(2, dtype=float) * q_rate

    def step(self, y: float, x: float) -> Tuple[float, float, float, float, float]:
        """Process a single sequential price observation (y_t, x_t).

        Returns:
            Tuple of (alpha_t, beta_t, innovation_e, innovation_std, zscore)
        """
        # 1. Prediction (Time Update)
        # theta_{t|t-1} = theta_{t-1}
        # P_{t|t-1} = P_{t-1} + Q
        p_prior = self.p_matrix + self.q_matrix

        # Measurement vector F_t = [1.0, x_t]^T
        f_vec = np.array([1.0, x], dtype=float)

        # Predicted measurement y_hat = F_t^T * theta_{t|t-1}
        y_hat = float(np.dot(f_vec, self.theta))

        # 2. Innovation (Residual error = instantaneous synthetic spread)
        e_t = float(y - y_hat)

        # Innovation variance S_t = F_t^T * P_{t|t-1} * F_t + R
        s_t = float(np.dot(f_vec, np.dot(p_prior, f_vec)) + self.r_var)
        s_std = float(np.sqrt(max(s_t, 1e-12)))

        # Standardized z-score
        z_t = float(e_t / s_std)

        # 3. Kalman Gain K_t = P_{t|t-1} * F_t / S_t
        k_gain = np.dot(p_prior, f_vec) / s_t

        # 4. Correction (Measurement Update)
        # theta_{t|t} = theta_{t|t-1} + K_t * e_t
        self.theta = self.theta + k_gain * e_t

        # Joseph form covariance update:
        # P_{t|t} = (I - K * F^T) * P * (I - K * F^T)^T + K * R * K^T
        # Guarantees numerical symmetry and positive semi-definiteness
        i_minus_kf = np.eye(2) - np.outer(k_gain, f_vec)
        self.p_matrix = np.dot(i_minus_kf, np.dot(p_prior, i_minus_kf.T)) + self.r_var * np.outer(k_gain, k_gain)

        alpha_t, beta_t = float(self.theta[0]), float(self.theta[1])
        return alpha_t, beta_t, e_t, s_std, z_t

    def filter_series(
        self,
        series_y: np.ndarray | pd.Series,
        series_x: np.ndarray | pd.Series,
        rolling_window: Optional[int] = 30
    ) -> KalmanFilterResult:
        """Filter entire historical price trajectories in batch mode.

        Args:
            series_y: Dependent asset prices Y_t.
            series_x: Independent asset prices X_t.
            rolling_window: Window size for empirical spread z-score standardization.
                            If None, uses theoretical innovation variance sqrt(S_t).

        Returns:
            KalmanFilterResult with full trajectories of parameters, spread, and z-scores.
        """
        y_arr = np.asarray(series_y, dtype=float)
        x_arr = np.asarray(series_x, dtype=float)
        n = len(y_arr)

        alpha_hist = np.zeros(n)
        beta_hist = np.zeros(n)
        spread_hist = np.zeros(n)
        spread_std_hist = np.zeros(n)
        zscore_hist = np.zeros(n)
        k_gains = np.zeros((n, 2))
        cov_hist = np.zeros((n, 2, 2))

        for t in range(n):
            alpha_t, beta_t, e_t, s_std, z_t = self.step(y_arr[t], x_arr[t])
            alpha_hist[t] = alpha_t
            beta_hist[t] = beta_t
            spread_hist[t] = e_t
            spread_std_hist[t] = s_std
            zscore_hist[t] = z_t
            cov_hist[t] = self.p_matrix.copy()

        # Scale-invariant rolling empirical z-score standardization
        if rolling_window is not None and rolling_window > 2 and n >= rolling_window:
            s_series = pd.Series(spread_hist)
            roll_mean = s_series.rolling(rolling_window, min_periods=max(5, rolling_window // 4)).mean()
            roll_std = s_series.rolling(rolling_window, min_periods=max(5, rolling_window // 4)).std().replace(0.0, 1.0).fillna(1.0)
            zscore_hist = ((s_series - roll_mean) / roll_std).fillna(0.0).values

        return KalmanFilterResult(
            alpha_history=alpha_hist,
            beta_history=beta_hist,
            spread_history=spread_hist,
            spread_std_history=spread_std_hist,
            zscore_history=zscore_hist,
            kalman_gains=k_gains,
            covariance_history=cov_hist
        )
