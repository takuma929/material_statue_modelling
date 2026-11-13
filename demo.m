% demo
% Run the whole analysis as it is set in config.json: the statistics of the
% whole statue, then the statistics around the gaze position for every
% eye-movement file named there, with a video of each trial if make_video
% is true. With the config.json of the repository, these are the three
% example recordings in data/trajectories/, a window of radius 1.5 deg and
% a video of each.
%
% Run it from the folder of the repository; the nine stimulus files must be
% in data/MAT-images/ (see README.md). To process other recordings or to
% use another window, edit config.json; this script does not change.
%
% Output, per recording:
%   results/local_statistics_<name>_r<radius>deg.mat   the statistics (variable Lc)
%   results/videos/<name>_r<radius>deg_trial<N>_<condition>.mp4
% and, once, results/global_statistics.mat (the statistics of the whole
% statue, which the videos show as a reference).
%
% Takes about 15 minutes with a parallel pool: 6 minutes for the whole
% statue (only the first time), then about 3 minutes per recording.

project_root = fileparts(mfilename('fullpath'));
addpath(fullfile(project_root, 'utils'));
cfg = load_config();                 % reads config.json

% statistics of the whole statue (all conditions and frames): computed once
if ~exist(fullfile(cfg.paths.results, 'global_statistics.mat'), 'file')
    compute_global_statistics();
end

% statistics around the gaze position: every file and radius of config.json
results = compute_local_statistics();

% a first look: where gaze was and what the window held, averaged over each trial
fprintf('\n');
for i = 1:numel(results)
    Lc = results{i};
    [~, name] = fileparts(Lc.source);
    k = @(stat) strcmp(Lc.names, stat);
    for t = 1:height(Lc.trials)
        fprintf('%s, condition %s, radius %g deg: gaze on the statue %.0f%% of the time, mean luminance %.3f, edge density %.2f\n', ...
            name, Lc.trials.condition(t), Lc.radius_deg, 100 * Lc.summary.mean(t, k('gaze_on_object')), ...
            Lc.summary.mean(t, k('lum_mean')), Lc.summary.mean(t, k('edge_density')));
    end
end
