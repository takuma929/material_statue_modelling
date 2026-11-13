function [gx, gy, valid, event, time] = gaze_per_step(trial, seq, ~)
% GAZE_PER_STEP  One gaze position for each frame step of the presentation.
%
%   [gx, gy, valid, event, time] = gaze_per_step(trial, seq) reduces
%   the gaze samples of a trial (load_trajectories) to one position per
%   frame step of the presentation (presentation_sequence): the median of
%   the samples recorded while that frame was on the screen. The eye
%   tracker samples much faster than the frames change, so this pairs every
%   frame with the place the observer was looking at while it was shown.
%
%   The time of every sample is read from the gaze file (Time_sec). The
%   file does not say when each frame appeared, so the frame steps of the
%   trial are spread evenly over the recording, from its first to its last
%   sample: the recording is taken to span exactly the presentation.
%
%   gx, gy   1 x T gaze position in image pixels; NaN where fewer than half
%            of the samples of the step are present (blink, track loss) or
%            where no sample falls in the step
%   valid    1 x T fraction of the step's samples that are present
%   event    1 x T most frequent event label of the samples of the step, as
%            given in the gaze file (NaN if the file has none)
%   time     1 x T onset of each step [s] from the first sample

T = numel(seq.frame);
gx = nan(1, T); gy = nan(1, T); valid = zeros(1, T); event = nan(1, T);
t = trial.t - trial.t(1);
if numel(t) > 1, sample = median(diff(t)); else, sample = 0; end
dt = (t(end) + sample) / T;                            % the recording, divided into T equal steps
time = (0:T - 1) * dt;
step = floor(t / dt) + 1;                              % frame step of each sample
ok = ~isnan(trial.x) & ~isnan(trial.y);
has_event = isfield(trial, 'event') && ~isempty(trial.event);
for j = 1:T
    in = step == j;
    if ~any(in), continue; end
    valid(j) = mean(ok(in));
    if valid(j) >= 0.5
        gx(j) = median(trial.x(in & ok));
        gy(j) = median(trial.y(in & ok));
    end
    if has_event
        event(j) = mode(trial.event(in));
    end
end
end
