function P = pair_maps(Ma, Mb, Mc, cfg, seed)
% PAIR_MAPS  Maps of the change between two successive frames.
%
%   P = pair_maps(Ma, Mb, Mc, cfg, seed)
%
%   Ma, Mb  maps (frame_maps, 'basic' is enough) of two frames that are
%           neighbours in rotation angle, in the order of increasing angle
%   Mc      maps of the frame one further step ahead (for the change of the
%           tracked fraction from one to two steps), or [] at the end
%   seed    seed of the random sampling of the rigid-motion fit
%
%   P holds what motion_statistics pools over a region:
%     dY, dL      absolute change of luminance and of L* between the frames
%     Ya, La, Lb  luminance of the first frame, L* of both
%     gLa         spatial gradient magnitude of L* in the first frame
%     hla, hlb    highlight maps of the two frames
%     common      pixels inside the statue in both frames (for dY ... hlb)
%     vx, vy      dense optical flow from the first to the second frame
%                 [px per frame step] (Farneback, estimated at
%                 cfg.flow.scale and brought back to full resolution)
%     speed, div, curl   magnitude, divergence and curl of the flow
%     valid       pixels where the flow is used: inside the statue in both
%                 frames and at least cfg.flow.border_px from the contour,
%                 because the flow at the silhouette describes the outline
%                 moving over the background, not the surface
%     pts         n x 2 grid of points [x y] on the statue in the first frame
%     tracked     n x 1, point followed to the second frame
%     tracked2    n x 1, point followed two steps ahead (empty without Mc)
%     vec         n x 2 displacement of each tracked point
%     tested, inlier   n x 1, point used in and consistent with a rigid 3-D
%                 motion of the whole statue (fundamental matrix, RANSAC)
%
%   The flow is computed for the direction of increasing angle only. On the
%   screen each pair is also played backward; to first order that reverses
%   the sign of the flow and leaves the statistics (all magnitudes) unchanged.

if nargin < 5, seed = 0; end

%% ---- frame difference ------------------------------------------------------
P.common = Ma.inner & Mb.inner;
P.dY = abs(Mb.Y - Ma.Y);
P.dL = abs(Mb.L - Ma.L);
P.Ya = Ma.Y; P.La = Ma.L; P.Lb = Mb.L; P.gLa = Ma.gL;
P.hla = Ma.hl; P.hlb = Mb.hl;
P.valid = imerode(P.common, strel('disk', cfg.flow.border_px, 0));

%% ---- dense flow (Farneback) on L* -----------------------------------------
% L* rather than luminance: the images are dark with a few very bright
% highlights, and L* gives the dark surface enough contrast to be followed.
sc = cfg.flow.scale;
Ia = imresize(min(max(Ma.L / 100, 0), 1) .* single(Ma.mask), sc, 'bilinear');
Ib = imresize(min(max(Mb.L / 100, 0), 1) .* single(Mb.mask), sc, 'bilinear');
est = opticalFlowFarneback('NumPyramidLevels', 4, 'NeighborhoodSize', 7, 'FilterSize', 15);
estimateFlow(est, Ia);
fl = estimateFlow(est, Ib);
[dvx_dx, dvx_dy] = gradient(fl.Vx);
[dvy_dx, dvy_dy] = gradient(fl.Vy);
sz = size(Ma.Y);
up = @(X) imresize(X, sz, 'bilinear');
P.vx = up(fl.Vx) / sc;                       % displacement in full-resolution pixels
P.vy = up(fl.Vy) / sc;
P.speed = hypot(P.vx, P.vy);
P.div  = up(dvx_dx + dvy_dy);                % derivatives of the flow do not depend on the scale
P.curl = up(dvy_dx - dvx_dy);

%% ---- tracked points (Kanade-Lucas-Tomasi) ---------------------------------
[rr, cc] = find(P.valid);
keep = mod(rr, cfg.flow.grid_px) == 0 & mod(cc, cfg.flow.grid_px) == 0;
P.pts = single([cc(keep), rr(keep)]);
n = size(P.pts, 1);
P.tracked = false(n, 1); P.tracked2 = []; P.vec = nan(n, 2, 'single');
P.tested = false(n, 1); P.inlier = false(n, 1);
if n < 20, return; end
Ja = min(max(Ma.L / 100, 0), 1); Jb = min(max(Mb.L / 100, 0), 1);
[p1, P.tracked] = track(Ja, Jb, P.pts, cfg);
P.vec(P.tracked, :) = p1(P.tracked, :) - P.pts(P.tracked, :);
if ~isempty(Mc)
    [~, P.tracked2] = track(Ja, min(max(Mc.L / 100, 0), 1), P.pts, cfg);
end

%% ---- consistency with one rigid 3-D motion --------------------------------
% Points on a rigidly rotating matte surface obey the epipolar constraint
% of one fundamental matrix; highlights slide over the surface and do not.
sp = hypot(P.vec(:, 1), P.vec(:, 2));
P.tested = P.tracked & sp > 0.25 * std(sp(P.tracked));
if nnz(P.tested) >= 16
    state = rng; rng(seed);                  % reproducible RANSAC
    try
        [~, inl] = estimateFundamentalMatrix(P.pts(P.tested, :), p1(P.tested, :), ...
            'Method', 'RANSAC', 'NumTrials', 1000, 'DistanceThreshold', cfg.flow.ransac_px, ...
            'DistanceType', 'Sampson');
        idx = find(P.tested);
        P.inlier(idx(inl)) = true;
    catch
        P.tested(:) = false;                 % no consistent solution: leave the cue undefined
    end
    rng(state);
else
    P.tested(:) = false;
end
end

% =========================================================================
function [p1, ok] = track(Ja, Jb, pts, cfg)
% Follow the points from image Ja to image Jb; a point counts as tracked
% when following it back returns to within cfg.flow.max_fb_error pixels.
tracker = vision.PointTracker('MaxBidirectionalError', cfg.flow.max_fb_error, ...
    'BlockSize', [15 15], 'NumPyramidLevels', 4);
initialize(tracker, pts, Ja);
[p1, ok] = tracker(Jb);
release(tracker);
end
