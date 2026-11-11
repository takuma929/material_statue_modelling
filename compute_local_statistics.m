function Lc = compute_local_statistics(trajectory_file, radius_deg, make_video)
% COMPUTE_LOCAL_STATISTICS  Statistics of the image around the gaze position.
%
%   compute_local_statistics(trajectory_file) reads a file of eye movements
%   (csv; format in utils/load_trajectories.m and README.md) and computes,
%   for every frame step of the presentation, the
%   statistics of utils/statistic_catalog.m inside a circular window
%   centred on the gaze position, on the frame that was on the screen at
%   that moment. The result is written to one file in results/.
%
%   compute_local_statistics(trajectory_file, radius_deg) sets the radius
%   of the window in degrees of visual angle (default 1.5, a window 3 deg
%   across).
%   compute_local_statistics(trajectory_file, radius_deg, true) also makes
%   a video of every trial for visual inspection (make_trajectory_video).
%   Lc = compute_local_statistics(...) also returns the result.
%
%   Examples (demo.m runs the three example files)
%     compute_local_statistics('data/trajectories/ABF_1_BR_gaze_trajectory_coordinates.csv')
%     compute_local_statistics('data/trajectories/ABF_1_BR_gaze_trajectory_coordinates.csv', 2.5)
%     compute_local_statistics('data/trajectories/ABF_1_BR_gaze_trajectory_coordinates.csv', 1.5, true)
%
%   What is computed at each frame step:
%     - the geometry of the window (how much of it lies on the statue, how
%       far gaze is from the contour, where on the statue it is)
%     - the image statistics of the frame within the window
%     - the motion statistics, within the window, of the change from this
%       frame to the next one shown
%   The functions are the ones that compute the statistics of the whole
%   statue (compute_global_statistics), applied to the pixels of the window,
%   so local and global values of a statistic are directly comparable.
%   Steps without gaze (blinks) or with less than cfg.window.min_coverage
%   of the window on the statue are NaN.
%
%   Output: results/local_statistics_<name>_r<radius>deg.mat, where <name>
%   is the name of the trajectory file. It holds one variable, Lc:
%     Lc.trials       table of the trials: trial, observer, condition, task
%     Lc.radius_deg   radius of the window [deg]
%     Lc.time         trials x T onset of each frame step [s] in the recording
%     Lc.frame, Lc.angle     1 x T the frame shown and the rotation angle at each step
%     Lc.gaze_x, Lc.gaze_y   trials x T gaze position per step [image px]
%     Lc.event        trials x T event label of each step, as given in the
%                     gaze file (the most frequent label of its samples; NaN
%                     if the file has none)
%     Lc.names        1 x K names; Lc.family, Lc.label
%     Lc.values       trials x T x K, [trial, frame step, statistic]
%     Lc.summary      per-trial summaries of each time series: .mean, .sd,
%                     .min, .max, .late_minus_early, .n_valid (trials x K)
%     Lc.catalog      table: name, family, scope, label and definition of
%                     every statistic
%     Lc.source       the trajectory file; Lc.cfg: the configuration used
%
%   Computation is organized by frame, not by trial: the maps of a frame
%   are computed once and every gaze window of every trial that falls on
%   that frame is pooled from them. A file with a few trials takes about
%   6 minutes with a parallel pool, and more trials add little.

project_root = fileparts(mfilename('fullpath'));
addpath(fullfile(project_root, 'utils'));
cfg = analysis_config();
if nargin < 1 || isempty(trajectory_file)
    error('compute_local_statistics:file', ...
        'Give the trajectory file, for example compute_local_statistics(''data/trajectories/ABF_1_BR_gaze_trajectory_coordinates.csv'').');
end
if nargin >= 2 && ~isempty(radius_deg)
    assert(isscalar(radius_deg) && radius_deg > 0, 'compute_local_statistics:radius', ...
        'The radius of the window must be a positive number [deg].');
    cfg.window.radius_deg = radius_deg;
end
if nargin < 3 || isempty(make_video), make_video = false; end
if ~exist(trajectory_file, 'file')                        % also accept a name inside data/trajectories/
    trajectory_file = fullfile(cfg.paths.trajectories, trajectory_file);
end
assert(exist(trajectory_file, 'file') == 2, 'compute_local_statistics:file', ...
    'Trajectory file not found: %s', trajectory_file);
[~, set_name] = fileparts(trajectory_file);
seq = presentation_sequence(cfg);
T = numel(seq.frame);
check_stimuli(cfg);

%% ---- gaze position at every frame step --------------------------------------
trials = load_trajectories(trajectory_file, cfg);
nT = numel(trials);
gx = nan(nT, T); gy = nan(nT, T); event = nan(nT, T); step_time = nan(nT, T);
for i = 1:nT
    assert(ismember(trials(i).condition, cfg.conditions), 'compute_local_statistics:condition', ...
        'Trial %d has the unknown condition "%s".', trials(i).trial, trials(i).condition);
    [gx(i, :), gy(i, :), ~, event(i, :), step_time(i, :)] = gaze_per_step(trials(i), seq, cfg);
end
fprintf('%s: %d trial(s), window radius %g deg (%.0f px)\n', set_name, nT, ...
    cfg.window.radius_deg, cfg.window.radius_deg * cfg.display.px_per_deg);

Tw = statistic_catalog('window'); Tf = statistic_catalog('frame'); Tp = statistic_catalog('pair');
nW = height(Tw); nS = height(Tf); nM = height(Tp);
values = nan(nT, T, nW + nS + nM);
nF = cfg.stimulus.n_frames; nP = size(seq.pair_frames, 1);

t0 = tic;
conds = unique({trials.condition}, 'stable');
for c = 1:numel(conds)
    cond = conds{c};
    ti = find(strcmp({trials.condition}, cond));          % trials of this condition
    masks = load_object_masks(cfg, cond);
    cgx = gx(ti, :); cgy = gy(ti, :);
    frames = load_frames(cfg, cond);                      % loaded once here; the workers receive single frames

    % ---- image statistics: one pass over the rendered frames ---------------
    out = cell(1, nF);
    parfor f = 1:nF
        [row, step] = find(~isnan(cgx) & seq.frame == f);  %#ok<PFBNS> windows that fall on this frame
        if isempty(row), continue; end
        M = frame_maps(frames(:, :, :, f), masks(:, :, f), cfg);
        v = nan(numel(row), nW + nS);
        for j = 1:numel(row)
            [reg, g] = gaze_window(M, cgx(row(j), step(j)), cgy(row(j), step(j)), cfg); %#ok<PFBNS>
            v(j, :) = [g, region_statistics(M, reg, cfg)];
        end
        out{f} = struct('row', row, 'step', step, 'v', v);
    end
    for f = 1:nF
        if isempty(out{f}), continue; end
        for j = 1:numel(out{f}.row)
            values(ti(out{f}.row(j)), out{f}.step(j), 1:nW + nS) = out{f}.v(j, :);
        end
    end

    % ---- motion statistics: one pass over the pairs of neighbouring frames -
    [rgb3, mask3] = frame_triplets(frames, masks, seq);
    out = cell(1, nP);
    first = seq.pair_frames(:, 1);                         % first frame of each pair (increasing angle)
    parfor p = 1:nP
        [row, step] = find(~isnan(cgx) & seq.pair == p);   %#ok<PFBNS> steps whose change is this pair
        if isempty(row), continue; end
        [Ma, Mb, Mc] = triplet_maps(rgb3{p}, mask3{p}, cfg);
        P = pair_maps(Ma, Mb, Mc, cfg, cfg.rng_seed + p);
        v = nan(numel(row), nM);
        for j = 1:numel(row)
            % the window is placed on the frame that was on the screen at this step
            if seq.frame(step(j)) == first(p), Mon = Ma; else, Mon = Mb; end
            reg = gaze_window(Mon, cgx(row(j), step(j)), cgy(row(j), step(j)), cfg); %#ok<PFBNS>
            v(j, :) = motion_statistics(P, reg, cfg);
        end
        out{p} = struct('row', row, 'step', step, 'v', v);
    end
    for p = 1:nP
        if isempty(out{p}), continue; end
        for j = 1:numel(out{p}.row)
            values(ti(out{p}.row(j)), out{p}.step(j), nW + nS + 1:end) = out{p}.v(j, :);
        end
    end
    fprintf('%s: %d trial(s) done (%d/%d conditions, %.1f min)\n', cond, numel(ti), c, numel(conds), toc(t0) / 60);
end

%% ---- assemble -----------------------------------------------------------------
Lc = struct();
Lc.trials = table([trials.trial]', string({trials.observer})', string({trials.condition})', string({trials.task})', ...
    'VariableNames', {'trial', 'observer', 'condition', 'task'});
Lc.radius_deg = cfg.window.radius_deg;
Lc.time = step_time; Lc.frame = seq.frame; Lc.angle = seq.angle;
Lc.gaze_x = gx; Lc.gaze_y = gy; Lc.event = event;
Lc.names  = [Tw.name; Tf.name; Tp.name]';
Lc.family = [Tw.family; Tf.family; Tp.family]';
Lc.label  = [Tw.label; Tf.label; Tp.label]';
Lc.values = values;
kinds = {'mean', 'sd', 'min', 'max', 'late_minus_early', 'n_valid'};
for k = 1:numel(kinds), Lc.summary.(kinds{k}) = nan(nT, numel(Lc.names)); end
for i = 1:nT
    S = summarize_series(reshape(values(i, :, :), T, []));
    for k = 1:numel(kinds), Lc.summary.(kinds{k})(i, :) = S.(kinds{k}); end
end
Lc.catalog = statistic_catalog();
Lc.source = trajectory_file;
Lc.cfg = cfg;

if ~exist(cfg.paths.results, 'dir'), mkdir(cfg.paths.results); end
file = fullfile(cfg.paths.results, sprintf('local_statistics_%s_r%gdeg.mat', set_name, cfg.window.radius_deg));
save(file, 'Lc');
fprintf('Local statistics: %d trial(s) x %d steps x %d statistics (%.0f%% of the steps valid) -> %s\n', ...
    nT, T, numel(Lc.names), 100 * mean(~isnan(values(:, :, 1 + nW)), 'all'), file);

if make_video
    make_trajectory_video(file);
end
if nargout == 0, clear Lc; end
end
