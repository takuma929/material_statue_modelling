function S = summarize_series(X)
% SUMMARIZE_SERIES  Summaries of the time series of each statistic.
%
%   S = summarize_series(X) takes X (T x K: one row per frame step of the
%   presentation, one column per statistic) and returns 1 x K summaries
%   over the steps, ignoring NaN (steps without gaze or with the window off
%   the statue):
%     S.mean, S.sd, S.min, S.max
%     S.late_minus_early   mean of the second half minus mean of the first half
%     S.n_valid            number of steps that entered
%   Note that hue_mean is an angle; summarize it with circular statistics.

half = floor(size(X, 1) / 2);
S.mean = mean(X, 1, 'omitnan');
S.sd   = std(X, 0, 1, 'omitnan');
S.min  = min(X, [], 1, 'omitnan');
S.max  = max(X, [], 1, 'omitnan');
S.late_minus_early = mean(X(half + 1:end, :), 1, 'omitnan') - mean(X(1:half, :), 1, 'omitnan');
S.n_valid = sum(~isnan(X), 1);
end
