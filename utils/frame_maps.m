function M = frame_maps(rgb, mask, cfg, level)
% FRAME_MAPS  Per-pixel maps of one frame from which the statistics are pooled.
%
%   M = frame_maps(rgb, mask, cfg) takes one frame (H x W x 3 linear RGB,
%   1 = display white; see load_frames) and the silhouette of the statue in
%   that frame (load_object_masks), and returns the images that every
%   statistic is computed from. Computing the maps once per frame and then
%   pooling them over a region (region_statistics) gives the statistics of
%   the whole object and of any number of gaze windows from the same maps,
%   so the two are directly comparable.
%
%   M = frame_maps(rgb, mask, cfg, 'basic') computes only the maps needed by
%   the motion statistics (pair_maps), which is much faster.
%
%   Fields of M (single precision, H x W unless noted):
%     Y, logY          luminance (Rec. 709 weights) and its log10
%     L, a, b          CIELAB relative to the display white (D65, Y = 1)
%     C, sat           chroma C*ab and saturation C*ab / L*
%     uvd              distance from D65 in the CIE 1976 u'v' diagram
%     satrgb, rg, yb   1 - min/max of RGB, and two opponent chromaticities
%     mask             silhouette of the statue
%     inner            mask without the band at the contour (object_region)
%     win, plateau     smooth spectral window and the pixels where it is 1
%     gx, gy, gL       gradient of L* and its magnitude
%     glog, glin       gradient magnitude of log10 luminance and of luminance
%     Yblur            local mean of luminance (Gaussian, cfg.stats.blur_deg)
%     band             H x W x 5 band-pass images of L*/100 (fine to coarse)
%     pyr              H x W x levels x orientations magnitude of the
%                      responses of a steerable pyramid
%     hl               highlights: brightest cfg.stats.hl_fraction of the object
%     dist             signed distance from the contour [px], positive inside
%     ref              scalars of the whole object in this frame: median,
%                      max (99.9th percentile) and highlight threshold of
%                      luminance, used as references by the gaze windows
%     geom             area, bounding box and centroid of the silhouette
%
%   Edge handling. The silhouette against the black background is not part
%   of the material, so: gradients are used only at pixels of 'inner',
%   where the whole difference stencil lies on the object; the local mean
%   and the band-pass images are normalized convolutions over 'inner', so
%   that no background pixel enters a blurred value; the pyramid is computed
%   on the image multiplied by 'win'.

if nargin < 4 || isempty(level), level = 'full'; end
full = strcmp(level, 'full');
rgb = single(rgb);
floor_ = single(cfg.stats.lum_floor);

%% ---- luminance and colour ----------------------------------------------
R = rgb(:, :, 1); G = rgb(:, :, 2); B = rgb(:, :, 3);
X = 0.4124 * R + 0.3576 * G + 0.1805 * B;            % CIE XYZ from linear sRGB
Y = 0.2126 * R + 0.7152 * G + 0.0722 * B;
Z = 0.0193 * R + 0.1192 * G + 0.9505 * B;
f = @(t) (t > (6/29)^3) .* nthroot(max(t, 0), 3) + (t <= (6/29)^3) .* (t / (3 * (6/29)^2) + 4/29);
fx = f(X / 0.9505); fy = f(Y); fz = f(Z / 1.0890);
M.Y = Y;
M.logY = log10(max(Y, floor_));
M.L = 116 * fy - 16;
M.mask = mask;
[M.inner, M.win, M.plateau] = object_region(mask, cfg.edge.border_px, cfg.edge.taper_px);

%% ---- highlights and references of the whole object ----------------------
y = sort(double(Y(M.inner)));
n = numel(y);
at = @(p) y(min(max(round(p / 100 * n), 1), n));      % percentile of the object's luminance
M.ref.median = at(50);
M.ref.max    = at(99.9);
M.ref.hl_thr = at(100 * (1 - cfg.stats.hl_fraction));
M.hl = M.inner & Y >= M.ref.hl_thr;

%% ---- geometry of the silhouette -----------------------------------------
[rr, cc] = find(mask);
M.geom.area     = numel(rr);
M.geom.bbox     = [min(rr) max(rr) min(cc) max(cc)];   % [top bottom left right]
M.geom.centroid = [mean(cc) mean(rr)];                 % [x y]
M.dist = single(bwdist(~mask) - bwdist(mask));

[M.gx, M.gy] = gradient(M.L);
M.gL = hypot(M.gx, M.gy);
if ~full, return; end

%% ---- remaining colour maps ----------------------------------------------
M.a = 500 * (fx - fy);
M.b = 200 * (fy - fz);
M.C = hypot(M.a, M.b);
M.sat = M.C ./ max(M.L, 1);
den = X + 15 * Y + 3 * Z;
up = 4 * X ./ max(den, 1e-6); vp = 9 * Y ./ max(den, 1e-6);
M.uvd = hypot(up - 0.1978, vp - 0.4683);
mx = max(rgb, [], 3); mn = min(rgb, [], 3);
M.satrgb = 1 - mn ./ max(mx, floor_);
M.rg = (R - G) ./ max(mx, floor_);
M.yb = ((R + G) / 2 - B) ./ max(mx, floor_);

%% ---- gradients -----------------------------------------------------------
[gx, gy] = gradient(M.logY); M.glog = hypot(gx, gy);
[gx, gy] = gradient(Y);      M.glin = hypot(gx, gy);

%% ---- local mean and band-pass images (normalized convolution) -----------
% blur(X) = G * (X . inner) / G * inner: a Gaussian average over the object
% pixels only, so the black background never darkens a blurred value.
support = single(M.inner);
nconv = @(img, sigma) imgaussfilt(img .* support, sigma, 'Padding', 0) ./ ...
    max(imgaussfilt(support, sigma, 'Padding', 0), 1e-6);
M.Yblur = nconv(Y, cfg.stats.blur_deg * cfg.display.px_per_deg);
Ln = M.L / 100;
sig = cfg.stats.band_sigma;
M.band = zeros([size(Y), numel(sig)], 'single');
fine = Ln;
for k = 1:numel(sig)
    coarse = nconv(Ln, sig(k));
    M.band(:, :, k) = fine - coarse;                   % detail between two successive scales
    fine = coarse;
end

%% ---- steerable pyramid on the windowed image ----------------------------
mu = sum(Ln(:) .* M.win(:)) / max(sum(M.win(:)), 1);
M.pyr = steerable_maps((Ln - mu) .* M.win, cfg.stats.pyr_levels, cfg.stats.pyr_orient);
end
