function [s, names, detail] = region_statistics(M, reg, cfg)
% REGION_STATISTICS  Image statistics of one frame pooled over a region.
%
%   [s, names, detail] = region_statistics(M, reg, cfg)
%
%   M     maps of the frame (frame_maps, level 'full')
%   reg   the region to pool over (object_window for the whole object,
%         gaze_window for a window centred on gaze):
%           reg.rows, reg.cols   rows and columns of a rectangle that holds the region
%           reg.mask             logical, numel(rows) x numel(cols): the pooled pixels
%                                (always inside M.inner)
%           reg.taper            window of the same size that is 1 inside the
%                                region and falls to 0 at the edge of a gaze
%                                window (all ones for the whole object)
%           reg.nfft             size of the Fourier transform
%   s      1 x K values, in the order of statistic_catalog('frame')
%   names  1 x K names
%   detail intermediate results, for illustrating the statistics: the
%          radial amplitude spectrum (spec_f [c/px], spec_amp, spec_fit =
%          coefficients of the fitted line in log10-log10 coordinates) and
%          the pyramid energies (pyr_E, levels x orientations)
%
%   The same function serves the whole object and the gaze windows, so a
%   local statistic is the global statistic restricted to the window.
%   References that define what a highlight is (the median luminance and
%   the brightest 5% of the object) always come from the whole object in
%   that frame (M.ref, M.hl); everything else is computed from the pixels of
%   the region alone. If the region has fewer than cfg.stats.min_pixels
%   pixels, every value is NaN.
%
%   See statistic_catalog for the definition of each statistic and
%   frame_maps for how the contour of the statue is kept out of them.

persistent NAMES
if isempty(NAMES)
    T = statistic_catalog('frame');
    NAMES = T.name';
end
names = NAMES;
s = nan(1, numel(names));
detail = struct('spec_f', [], 'spec_amp', [], 'spec_fit', [], 'pyr_E', []);
if isempty(reg) || nnz(reg.mask) < cfg.stats.min_pixels, return; end

r = reg.rows; c = reg.cols; R = reg.mask;
n = nnz(R);
pick = @(X) double(X(r, c));          % a map cropped to the rectangle of the region
vals = @(X) double(X(R));             % values of a cropped map inside the region
v = struct();

%% ---- luminance -----------------------------------------------------------
Y = pick(M.Y); y = Y(R); ys = sort(y);
[mu, sd, sk, ku] = moments(y);
v.lum_mean = mu; v.lum_median = pctl(ys, 50); v.lum_sd = sd; v.lum_skew = sk; v.lum_kurt = ku;
v.lum_rms_contrast = sd / max(mu, eps);
v.lum_p01 = pctl(ys, 1);  v.lum_p10 = pctl(ys, 10); v.lum_p25 = pctl(ys, 25); v.lum_p75 = pctl(ys, 75);
v.lum_p90 = pctl(ys, 90); v.lum_p99 = pctl(ys, 99); v.lum_p999 = pctl(ys, 99.9); v.lum_max = ys(end);
v.lum_michelson = (v.lum_p99 - v.lum_p01) / max(v.lum_p99 + v.lum_p01, eps);
v.lum_dark_frac = mean(y < 0.2 * mu);
v.lum_bright_frac = mean(y > 0.5);
ly = vals(pick(M.logY)); ls = sort(ly);
[v.loglum_mean, v.loglum_sd, v.loglum_skew, v.loglum_kurt] = moments(ly);
v.loglum_range = pctl(ls, 99.9) - pctl(ls, 1);
v.loglum_upper_tail = pctl(ls, 99) - pctl(ls, 50);
v.loglum_lower_tail = pctl(ls, 50) - pctl(ls, 1);

%% ---- color ---------------------------------------------------------------
Lp = pick(M.L);
L = Lp(R); a = vals(pick(M.a)); b = vals(pick(M.b)); C = vals(pick(M.C)); sat = vals(pick(M.sat));
chan = struct('lightness', L, 'a', a, 'b', b, 'chroma', C, 'saturation', sat);
cn = fieldnames(chan);
for k = 1:numel(cn)
    x = chan.(cn{k}); xs = sort(x);
    [m1, m2, m3, m4] = moments(x);
    v.([cn{k} '_mean']) = m1; v.([cn{k} '_median']) = pctl(xs, 50); v.([cn{k} '_sd']) = m2;
    v.([cn{k} '_skew']) = m3; v.([cn{k} '_kurt']) = m4;
    v.([cn{k} '_p01']) = pctl(xs, 1); v.([cn{k} '_p99']) = pctl(xs, 99);
end
% hue: (a*, b*) = C (cos h, sin h), so the sums of a* and b* are the
% chroma-weighted sums of the unit hue vectors
sx = sum(a); sy = sum(b);
v.hue_mean = mod(atan2d(sy, sx), 360);
v.hue_sd = rad2deg(sqrt(-2 * log(max(hypot(sx, sy) / max(sum(C), eps), eps))));
uvd = vals(pick(M.uvd));
lit = y > cfg.stats.chroma_min_lum;           % chromaticity is undefined for black pixels
if nnz(lit) >= 10
    v.uv_dist_mean = mean(uvd(lit)); v.uv_dist_sd = std(uvd(lit));
    v.corr_lum_uv_dist = pearson(y(lit), uvd(lit));
else
    v.uv_dist_mean = NaN; v.uv_dist_sd = NaN; v.corr_lum_uv_dist = NaN;
end
satrgb_p = pick(M.satrgb); satrgb = satrgb_p(R);
v.sat_rgb_mean = mean(satrgb); v.sat_rgb_sd = std(satrgb);

%% ---- color-luminance correlations ----------------------------------------
v.corr_lightness_saturation = pearson(L, sat);
v.corr_lightness_chroma = pearson(L, C);
v.corr_lightness_b = pearson(L, b);
v.corr_loglum_sat_rgb = pearson(ly, satrgb);

%% ---- contrast ------------------------------------------------------------
lo = max(pctl(ys, 0.1), cfg.stats.lum_floor);
v.contrast_dynamic_range = log10(max(pctl(ys, 99.9), lo) / lo);
k1 = max(round(0.01 * n), 1);
v.contrast_robust_range = log10(max(mean(ys(end - k1 + 1:end)), cfg.stats.lum_floor) / max(mean(ys(1:k1)), cfg.stats.lum_floor));
v.contrast_local = mean(abs(y - mu)) / max(mu, eps);
Bm = vals(pick(M.Yblur));
v.contrast_local_blur = mean(abs(y - Bm)) / max(mean(Bm), eps);
ms = @(cc) mean(abs(cc) .^ 2.4 ./ (1 + abs(cc) .^ 2));
v.contrast_meese_summers = ms((y - mu) / max(mu, eps));
v.contrast_meese_summers_blur = ms((y - Bm) ./ max(Bm, cfg.stats.lum_floor));

%% ---- highlights ----------------------------------------------------------
% thresholds relative to the whole object in this frame
v.hl_cover_2x  = mean(y > 2 * M.ref.median);
v.hl_cover_4x  = mean(y > 4 * M.ref.median);
v.hl_cover_8x  = mean(y > 8 * M.ref.median);
v.hl_cover_16x = mean(y > 16 * M.ref.median);
v.hl_frac_half_max = mean(y > 0.5 * M.ref.max);
hl = M.hl(r, c) & R;
gL = pick(M.gL);
nh = nnz(hl);
v.hl_coverage = nh / n;
if nh > 0
    v.hl_contrast = log10(mean(Y(hl))) - log10(max(v.lum_median, cfg.stats.lum_floor));
    cc = bwconncomp(hl);
    st = regionprops(cc, 'Area', 'MajorAxisLength', 'MinorAxisLength', 'Orientation');
    areas = [st.Area];
    v.hl_n_regions = cc.NumObjects / n * 1e4;
    v.hl_mean_area = mean(areas);
    v.hl_area_cv = std(areas) / mean(areas);
    big = areas >= cfg.stats.hl_min_area;
    if any(big)
        w = areas(big);
        elong = [st(big).MajorAxisLength] ./ max([st(big).MinorAxisLength], 1);
        v.hl_elongation = sum(elong .* w) / sum(w);
        th = deg2rad([st(big).Orientation]);
        v.hl_orient_coherence = abs(sum(w .* exp(2i * th))) / sum(w);
    else
        v.hl_elongation = NaN; v.hl_orient_coherence = NaN;
    end
    rim = hl & ~imerode(hl, ones(3));               % boundary pixels of the highlights
    v.hl_sharpness = mean(gL(rim));
    v.hl_texture = mean(gL(hl)) / max(std(L), eps);
    v.sat_highlight = mean(satrgb_p(hl));
    rg = pick(M.rg); yb = pick(M.yb);
    v.hl_rg = mean(rg(hl)); v.hl_yb = mean(yb(hl));
else
    v.hl_contrast = NaN; v.hl_n_regions = 0; v.hl_mean_area = 0; v.hl_area_cv = NaN;
    v.hl_elongation = NaN; v.hl_orient_coherence = NaN; v.hl_sharpness = NaN; v.hl_texture = NaN;
    v.sat_highlight = NaN; v.hl_rg = NaN; v.hl_yb = NaN;
end
body = R & ~hl;
if any(body(:)), v.sat_body = median(satrgb_p(body)); else, v.sat_body = NaN; end
v.sat_highlight_drop = v.sat_body - v.sat_highlight;

%% ---- spatial: gradients ---------------------------------------------------
g = gL(R);
[v.edge_density, ~, v.grad_skew, v.grad_kurt] = moments(g);
v.edge_density_log = mean(vals(pick(M.glog)));
v.edge_energy = mean(vals(pick(M.glin)));
gx = vals(pick(M.gx)); gy = vals(pick(M.gy));
v.orient_coherence = abs(sum(g .* exp(2i * atan2(gy, gx)))) / max(sum(g), eps);
v.orient_vh_ratio = log10(max(sum(abs(gy)), eps) / max(sum(abs(gx)), eps));

%% ---- spatial: band-pass contrast -----------------------------------------
nb = size(M.band, 3);
band = zeros(1, nb);
for k = 1:nb
    band(k) = std(vals(M.band(r, c, k)));
    v.(sprintf('band_rms_%d', k)) = band(k);
end
v.band_fine_coarse = log10(max(sum(band(1:2)), eps) / max(sum(band(nb - 1:nb)), eps));

%% ---- spatial: amplitude spectrum -----------------------------------------
% window = (smooth window inside the silhouette) x (taper of the gaze window)
w = double(M.win(r, c)) .* reg.taper;
sw = sum(w(:));
if sw >= cfg.stats.min_pixels / 2
    x = Lp / 100;
    x = (x - sum(x(:) .* w(:)) / sw) .* w;
    N = reg.nfft;
    if any(size(x) > N)                              % larger than the transform: keep the centre
        r0 = floor((size(x, 1) - min(size(x, 1), N)) / 2); c0 = floor((size(x, 2) - min(size(x, 2), N)) / 2);
        x = x(r0 + (1:min(size(x, 1), N)), c0 + (1:min(size(x, 2), N)));
    end
    P = abs(fftshift(fft2(x, N, N))) .^ 2 / (N ^ 2 * sum(w(:) .^ 2));   % sum(P) = weighted variance
    [f, theta] = frequency_grid(N);
    P(f == 0) = 0;
    fit = cfg.stats.spec_fit;
    edges = logspace(log10(fit(1)), log10(fit(2)), 13);
    centre = sqrt(edges(1:end - 1) .* edges(2:end));
    radial = zeros(1, numel(centre));
    for k = 1:numel(centre)
        radial(k) = mean(P(f >= edges(k) & f < edges(k + 1)));
    end
    p = polyfit(log10(centre), log10(sqrt(radial) + realmin), 1);
    v.spec_slope = p(1);
    detail.spec_f = centre; detail.spec_amp = sqrt(radial); detail.spec_fit = p;
    sb = cfg.stats.spec_bands;
    v.spec_rms_low  = sqrt(sum(P(f < sb(1))));
    v.spec_rms_mid  = sqrt(sum(P(f >= sb(1) & f < sb(2))));
    v.spec_rms_high = sqrt(sum(P(f >= sb(2))));
    v.spec_low_high_ratio = log10(max(sum(P(f < 1/16)), realmin) / max(sum(P(f >= 1/16)), realmin));
    sel = f >= fit(1) & f <= fit(2);
    th = theta(sel); Ps = P(sel);
    nbin = 18;
    bin = min(floor(th / pi * nbin) + 1, nbin);
    q = accumarray(bin, Ps, [nbin 1]) / max(sum(Ps), realmin);
    v.spec_orient_entropy = -sum(q .* log(q + realmin)) / log(nbin);
    v.spec_orient_concentration = abs(sum(Ps .* exp(2i * th))) / max(sum(Ps), realmin);
else
    v.spec_slope = NaN; v.spec_rms_low = NaN; v.spec_rms_mid = NaN; v.spec_rms_high = NaN;
    v.spec_low_high_ratio = NaN; v.spec_orient_entropy = NaN; v.spec_orient_concentration = NaN;
end

%% ---- spatial: steerable pyramid ------------------------------------------
% responses are averaged where the spectral window is 1 (clear of the contour)
Rp = R & M.plateau(r, c);
nl = size(M.pyr, 3); no = size(M.pyr, 4);
if nnz(Rp) >= cfg.stats.min_pixels / 2
    E = zeros(nl, no);
    for l = 1:nl
        for k = 1:no
            e = M.pyr(r, c, l, k);
            E(l, k) = mean(e(Rp));
        end
    end
    lev = log10(sum(E, 2) + realmin);
    detail.pyr_E = E;
    for l = 1:nl, v.(sprintf('pyr_level_%d', l)) = lev(l); end
    v.pyr_fine_coarse = lev(1) - lev(nl);
    v.pyr_anisotropy_fine = std(E(1, :)) / max(mean(E(1, :)), realmin);
    v.pyr_anisotropy_coarse = std(E(nl, :)) / max(mean(E(nl, :)), realmin);
else
    for l = 1:nl, v.(sprintf('pyr_level_%d', l)) = NaN; end
    v.pyr_fine_coarse = NaN; v.pyr_anisotropy_fine = NaN; v.pyr_anisotropy_coarse = NaN;
end

%% ---- collect in the order of the catalog ----------------------------------
for k = 1:numel(names)
    s(k) = v.(names{k});
end
end

% =========================================================================
function [mu, sd, sk, ku] = moments(x)
% Mean, standard deviation, skewness and kurtosis (normal distribution = 3).
mu = mean(x);
d = x - mu;
m2 = mean(d .^ 2);
sd = sqrt(m2 * numel(x) / max(numel(x) - 1, 1));
sk = mean(d .^ 3) / max(m2 ^ 1.5, realmin);
ku = mean(d .^ 4) / max(m2 ^ 2, realmin);
end

function p = pctl(xs, q)
% q-th percentile of the sorted vector xs (linear interpolation, as prctile).
n = numel(xs);
pos = min(max(q / 100 * n + 0.5, 1), n);
i = floor(pos); j = min(i + 1, n);
p = xs(i) + (pos - i) * (xs(j) - xs(i));
end

function rho = pearson(x, y)
x = x - mean(x); y = y - mean(y);
rho = sum(x .* y) / max(sqrt(sum(x .^ 2) * sum(y .^ 2)), realmin);
end

function [f, theta] = frequency_grid(N)
% Radial frequency [cycles per pixel] and orientation of an N x N transform.
persistent CACHE
key = sprintf('n%d', N);
if isempty(CACHE) || ~isfield(CACHE, key)
    [fx, fy] = meshgrid((-N / 2:N / 2 - 1) / N);
    CACHE.(key).f = hypot(fx, fy);
    CACHE.(key).theta = mod(atan2(fy, fx), pi);
end
f = CACHE.(key).f; theta = CACHE.(key).theta;
end
