% demo
% Compute the statistics around the gaze position for the three example
% recordings in data/trajectories/, and make a video of each for checking
% by eye. Run it from the folder of the repository; the nine stimulus files
% must be in data/MAT-images/ (see README.md).
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
cfg = analysis_config();

% the recordings: observer ABF, one trial each (the file name gives the
% question asked and the condition, statue followed by material)
files = {'ABF_1_BR_gaze_trajectory_coordinates.csv', ...
         'ABF_2_PS_gaze_trajectory_coordinates.csv', ...
         'ABF_HC_3_gaze_trajectory_coordinates.csv'};

radius_deg = 1.5;       % radius of the window around the gaze position [deg of visual angle]
make_video = true;      % also make a video of each recording

% statistics of the whole statue (all conditions and frames): computed once
if ~exist(fullfile(cfg.paths.results, 'global_statistics.mat'), 'file')
    compute_global_statistics();
end

% statistics around the gaze position, one result file per recording
for i = 1:numel(files)
    Lc = compute_local_statistics(fullfile(cfg.paths.trajectories, files{i}), radius_deg, make_video);

    % a first look: where gaze was and what the window held, averaged over the trial
    k = @(name) strcmp(Lc.names, name);
    fprintf('  %s, condition %s: gaze on the statue %.0f%% of the time, mean luminance %.3f, edge density %.2f\n\n', ...
        files{i}, Lc.trials.condition(1), 100 * Lc.summary.mean(1, k('gaze_on_object')), ...
        Lc.summary.mean(1, k('lum_mean')), Lc.summary.mean(1, k('edge_density')));
end
