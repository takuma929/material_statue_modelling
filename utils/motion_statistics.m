function [s, names] = motion_statistics(P, reg, cfg)
% MOTION_STATISTICS  Statistics of the change between two frames, pooled over a region.
%
%   [s, names] = motion_statistics(P, reg, cfg)
%
%   P     maps of a frame pair (pair_maps)
%   reg   region to pool over (object_window or gaze_window), see
%         region_statistics
%   s     1 x K values in the order of statistic_catalog('pair'):
%         temporal   change of luminance between the two frames
%         flow       dense optical flow
%         tracking   the optic-flow cues to shininess of Doerschner et al.
%                    (2011): how many surface points can be followed, how
%                    fast that number falls with the frame distance, and
%                    whether the motion fits one rigid 3-D object
%
%   The temporal statistics use the region pixels that are inside the
%   statue in both frames; the flow and tracking statistics leave out a
%   further band at the contour (P.valid). Values are NaN when too few
%   pixels or points remain.

persistent NAMES
if isempty(NAMES)
    T = statistic_catalog('pair');
    NAMES = T.name';
end
names = NAMES;
s = nan(1, numel(names));
if isempty(reg), return; end
r = reg.rows; c = reg.cols;
v = cell2struct(num2cell(nan(numel(names), 1)), names, 1);

%% ---- temporal --------------------------------------------------------------
R = reg.mask & P.common(r, c);
if nnz(R) >= cfg.stats.min_pixels
    get = @(X) double(X(R));
    crop = @(X) X(r, c);
    dY = get(crop(P.dY)); dL = get(crop(P.dL));
    v.diff_energy = mean(dY);
    v.diff_energy_lightness = mean(dL);
    v.temporal_contrast = mean(dY) / max(mean(get(crop(P.Ya))), eps);
    v.temporal_spatial_ratio = log10(max(mean(dL), realmin) / max(mean(get(crop(P.gLa))), realmin));
    La = get(crop(P.La)); Lb = get(crop(P.Lb));
    La = La - mean(La); Lb = Lb - mean(Lb);
    v.decorrelation = 1 - sum(La .* Lb) / max(sqrt(sum(La .^ 2) * sum(Lb .^ 2)), realmin);
    ha = P.hla(r, c) & R; hb = P.hlb(r, c) & R;
    if nnz(ha) + nnz(hb) > 0
        v.hl_persistence = 2 * nnz(ha & hb) / (nnz(ha) + nnz(hb));
    end
end

%% ---- dense flow ------------------------------------------------------------
R = reg.mask & P.valid(r, c);
if nnz(R) >= cfg.stats.min_pixels
    vx = double(P.vx(r, c)); vy = double(P.vy(r, c));
    sp = hypot(vx, vy);
    v.flow_speed = mean(sp(R));
    v.flow_speed_sd = std(sp(R));
    v.flow_dir_coherence = hypot(mean(vx(R)), mean(vy(R))) / max(v.flow_speed, eps);
    % residual of an affine model of the flow over the region
    [cc, rr] = meshgrid(c, r);
    X = [ones(nnz(R), 1), cc(R), rr(R)];
    res = zeros(size(sp));
    res(R) = hypot(vx(R) - X * (X \ vx(R)), vy(R) - X * (X \ vy(R)));
    v.flow_residual = mean(res(R)) / max(v.flow_speed, eps);
    hl = P.hla(r, c) & R; body = R & ~hl;
    if nnz(hl) >= 10 && nnz(body) >= 10
        v.flow_hl_speed = mean(sp(hl));
        v.flow_hl_body_ratio = log10(max(mean(sp(hl)), realmin) / max(mean(sp(body)), realmin));
        v.flow_hl_residual_ratio = mean(res(hl)) / max(mean(res(R)), realmin);
    end
    dv = double(P.div(r, c)); cu = double(P.curl(r, c));
    v.flow_divergence = mean(abs(dv(R)));
    v.flow_curl = mean(abs(cu(R)));
    v.flow_div_frac = mean(abs(dv(R)) > cfg.flow.div_thresh);
end

%% ---- tracked points --------------------------------------------------------
if ~isempty(P.pts)
    x = double(P.pts(:, 1)); y = double(P.pts(:, 2));
    in = x >= c(1) & x <= c(end) & y >= r(1) & y <= r(end);
    idx = find(in);
    in(idx) = reg.mask(sub2ind(size(reg.mask), y(idx) - r(1) + 1, x(idx) - c(1) + 1));
    if nnz(in) >= 10
        cov1 = mean(P.tracked(in));
        v.track_coverage = cov1;
        if ~isempty(P.tracked2) && cov1 > 0
            v.track_coverage_change = 100 * (cov1 - mean(P.tracked2(in))) / cov1;
        end
        tr = in & P.tracked;
        if any(tr)
            v.track_speed = mean(hypot(P.vec(tr, 1), P.vec(tr, 2)));
        end
        te = in & P.tested;
        if nnz(te) >= 10
            v.track_rigid_inlier = mean(P.inlier(te));
        end
    end
end

for k = 1:numel(names)
    s(k) = v.(names{k});
end
end
