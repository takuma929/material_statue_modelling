function [reg, g] = gaze_window(M, x, y, cfg)
% GAZE_WINDOW  Circular window centred on gaze, and where it lies on the statue.
%
%   [reg, g] = gaze_window(M, x, y, cfg)
%
%   M      maps of the frame on the screen (frame_maps; 'basic' is enough)
%   x, y   gaze position in image pixels (x rightward, y downward; the
%          centre of the top-left pixel is (1, 1))
%
%   reg    the region for region_statistics and motion_statistics: the
%          object pixels inside a disk of radius cfg.window.radius_deg
%          around gaze. Fields rows, cols, mask, taper, nfft (see region_statistics).
%          'taper' is 1 in the centre of the disk and falls to 0 at its rim
%          as a raised cosine over the outer cfg.window.taper_frac of the
%          radius, so that the rim of the window adds no spectral energy.
%          reg is empty when gaze is missing (NaN), when the window lies
%          off the image, or when less than cfg.window.min_coverage of the
%          window is on the statue; the statistics are then NaN.
%   g      1 x K geometry of the window, in the order of
%          statistic_catalog('window'): coverage, gaze on the object,
%          signed distance to the contour, position within the bounding
%          box, distance from the centroid.

names = window_names();
g = nan(1, numel(names));
reg = [];
if isnan(x) || isnan(y), return; end

[H, W] = size(M.mask);
ppd = cfg.display.px_per_deg;
rad = cfg.window.radius_deg * ppd;                  % radius [px]

%% ---- geometry of the gaze position ---------------------------------------
xi = round(x); yi = round(y);
on_image = xi >= 1 && xi <= W && yi >= 1 && yi <= H;
bb = M.geom.bbox;
v.gaze_on_object = double(on_image && M.mask(yi, xi));
if on_image
    v.gaze_dist_to_contour_deg = double(M.dist(yi, xi)) / ppd;
else
    v.gaze_dist_to_contour_deg = NaN;
end
v.gaze_x_rel = (x - bb(3)) / max(bb(4) - bb(3), 1);
v.gaze_y_rel = (y - bb(1)) / max(bb(2) - bb(1), 1);
v.gaze_ecc_deg = hypot(x - M.geom.centroid(1), y - M.geom.centroid(2)) / ppd;

%% ---- pixels of the window -------------------------------------------------
rows = max(1, floor(y - rad)):min(H, ceil(y + rad));
cols = max(1, floor(x - rad)):min(W, ceil(x + rad));
v.win_coverage = 0;
if ~isempty(rows) && ~isempty(cols)
    [cc, rr] = meshgrid(cols, rows);
    d = hypot(cc - x, rr - y);
    disk = d <= rad;
    mask = disk & M.inner(rows, cols);
    v.win_coverage = min(nnz(mask) / (pi * rad ^ 2), 1);    % pixel count over the area of the disk
    if v.win_coverage >= cfg.window.min_coverage
        t = cfg.window.taper_frac;
        reg.rows  = rows;
        reg.cols  = cols;
        reg.mask  = mask;
        reg.taper = 0.5 * (1 + cos(pi * min(max((d / rad - (1 - t)) / t, 0), 1)));
        reg.nfft  = max(cfg.window.nfft, 2 ^ nextpow2(max(numel(rows), numel(cols))));   % holds the whole window
    end
end

for k = 1:numel(names)
    g(k) = v.(names{k});
end
end

function names = window_names()
persistent NAMES
if isempty(NAMES)
    T = statistic_catalog('window');
    NAMES = T.name';
end
names = NAMES;
end
