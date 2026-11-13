function G = compute_global_statistics(refresh_masks)
% COMPUTE_GLOBAL_STATISTICS  Image and video statistics of the whole statue.
%
%   compute_global_statistics computes, for each of the nine conditions,
%   every statistic of utils/statistic_catalog.m over the whole statue,
%   without any gaze data:
%     - the image statistics of each of the 61 rendered frames
%     - the motion statistics of each of the 60 pairs of neighbouring frames
%     - the statistics of the whole presented sequence
%   and writes them to one file, results/global_statistics.mat.
%
%   G = compute_global_statistics also returns the result.
%   compute_global_statistics(true) first rebuilds the cached silhouettes
%   (needed after stimulus files are replaced in place; a change of the
%   stimulus format or folder in config.json is detected automatically).
%
%   The stimulus files must be in data/MAT-images/ (see README.md).
%
%   results/global_statistics.mat holds one variable, G:
%     G.conditions      1 x 9 condition names; G.statue, G.material: their two factors
%     G.frame.names     names of the per-frame statistics (image statistics,
%                       then the geometry of the silhouette); .family, .label
%     G.frame.values    9 x 61 x K, [condition, rendered frame, statistic]
%     G.pair.names      names of the motion statistics; .family, .label
%     G.pair.values     9 x 60 x K, [condition, frame pair, statistic]
%     G.pair.frames     60 x 2 rendered frames of each pair
%     G.clip.names      names of the sequence statistics; .family, .label
%     G.clip.values     9 x K
%     G.summary         summaries over the presented sequence (240 frame
%                       steps) of every per-frame and motion statistic:
%                       .names, .mean, .sd, .min, .max (9 x K)
%     G.sequence        the presentation sequence (frame shown at each step)
%     G.catalog         table: name, family, scope, label and definition of
%                       every statistic
%     G.cfg             the configuration used
%   To get the time course of a statistic during a trial, index the frame
%   values with the sequence: squeeze(G.frame.values(c, G.sequence.frame, k)).
%
%   Takes about 6 minutes with a parallel pool of ten workers (Parallel
%   Computing Toolbox); without one the loops run serially.

if nargin < 1, refresh_masks = false; end
project_root = fileparts(mfilename('fullpath'));
addpath(fullfile(project_root, 'utils'));
cfg = load_config();
seq = presentation_sequence(cfg);
check_stimuli(cfg);
if ~exist(cfg.paths.results, 'dir'), mkdir(cfg.paths.results); end
if refresh_masks && exist(cfg.paths.cache, 'dir')
    delete(fullfile(cfg.paths.cache, 'masks_*.mat'));
end

Tf = statistic_catalog('frame'); To = statistic_catalog('object');
Tp = statistic_catalog('pair');  Tc = statistic_catalog('clip');
nC = numel(cfg.conditions); nF = cfg.stimulus.n_frames; nP = size(seq.pair_frames, 1);
frame_values = nan(nC, nF, height(Tf) + height(To));
pair_values  = nan(nC, nP, height(Tp));
clip_values  = nan(nC, height(Tc));

t0 = tic;
for c = 1:nC
    cond = cfg.conditions{c};
    masks = load_object_masks(cfg, cond);
    frames = load_frames(cfg, cond);                   % loaded once here; the workers receive single frames

    % ---- image statistics of every frame, pooled over the whole statue ----
    fv = nan(nF, height(Tf) + height(To));
    parfor k = 1:nF
        M = frame_maps(frames(:, :, :, k), masks(:, :, k), cfg);
        fv(k, :) = [region_statistics(M, object_window(M, cfg), cfg), object_geometry(M, cfg)];
    end
    frame_values(c, :, :) = fv;

    % ---- motion statistics of every pair of neighbouring frames -----------
    % each pair with, if there is one, the next frame in rotation angle
    [rgb3, mask3] = frame_triplets(frames, masks, seq);
    pv = nan(nP, height(Tp));
    parfor p = 1:nP
        [Ma, Mb, Mc] = triplet_maps(rgb3{p}, mask3{p}, cfg);
        P = pair_maps(Ma, Mb, Mc, cfg, cfg.rng_seed + p);
        pv(p, :) = motion_statistics(P, object_window(Ma, cfg), cfg);
    end
    pair_values(c, :, :) = pv;

    % ---- statistics of the whole presented sequence ------------------------
    clip_values(c, :) = clip_statistics(frames, masks, seq, cfg);
    fprintf('%s done (%d/%d, %.1f min)\n', cond, c, nC, toc(t0) / 60);
end

%% ---- assemble ---------------------------------------------------------------
G = struct();
G.conditions = cfg.conditions;
G.statue     = cellfun(@(s) s(1), cfg.conditions, 'UniformOutput', false);
G.material   = cellfun(@(s) s(2), cfg.conditions, 'UniformOutput', false);
G.frame.names  = [Tf.name; To.name]';   G.frame.family = [Tf.family; To.family]';
G.frame.label  = [Tf.label; To.label]'; G.frame.values = frame_values;
G.pair.names   = Tp.name';   G.pair.family = Tp.family'; G.pair.label = Tp.label';
G.pair.values  = pair_values; G.pair.frames = seq.pair_frames;
G.clip.names   = Tc.name';   G.clip.family = Tc.family'; G.clip.label = Tc.label';
G.clip.values  = clip_values;

% summaries over the presented sequence: the value of each statistic at
% every frame step (motion statistics describe the change to the next step)
G.summary.names = [G.frame.names, G.pair.names];
kinds = {'mean', 'sd', 'min', 'max'};
for i = 1:numel(kinds), G.summary.(kinds{i}) = nan(nC, numel(G.summary.names)); end
steps = ~isnan(seq.pair);
for c = 1:nC
    series = nan(numel(seq.frame), numel(G.summary.names));
    series(:, 1:numel(G.frame.names)) = squeeze(frame_values(c, seq.frame, :));
    series(steps, numel(G.frame.names) + 1:end) = squeeze(pair_values(c, seq.pair(steps), :));
    S = summarize_series(series);
    for i = 1:numel(kinds), G.summary.(kinds{i})(c, :) = S.(kinds{i}); end
end
G.sequence = seq;
G.catalog  = statistic_catalog();
G.cfg      = cfg;

file = fullfile(cfg.paths.results, 'global_statistics.mat');
save(file, 'G');
fprintf('Global statistics: %d conditions, %d per-frame, %d motion and %d sequence statistics -> %s\n', ...
    nC, numel(G.frame.names), numel(G.pair.names), numel(G.clip.names), file);
if nargout == 0, clear G; end
end
