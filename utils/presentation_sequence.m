function seq = presentation_sequence(cfg)
% PRESENTATION_SEQUENCE  Which rendered frame was on the screen at each moment.
%
%   seq = presentation_sequence(cfg) describes the sinusoidal presentation
%   of a trial. The statue swings about its central view; the 61 rendered
%   frames sample the swing at equal time steps:
%
%       frame  1        central view (angle 0)
%       frames 2 - 31   centre -> extreme on the right (angle  sin(pi/2 * k/30))
%       frames 32 - 61  centre -> extreme on the left  (angle -sin(pi/2 * k/30))
%
%   In the order of the rotation angle the frames are 61 60 ... 32 1 2 ...
%   31. A cycle walks through this order and back, 120 frame steps, from
%   the frame shown first (cfg.presentation.start_frame): with frame 61,
%   the extreme on the left, a cycle is 61 60 ... 32 1 2 ... 31 30 ... 2 1
%   32 ... 60 (to the right, then back to the left). If the trial starts
%   between the extremes (frame 1 is the central view),
%   cfg.presentation.start_direction gives the first movement: 1 to the
%   right, -1 to the left. A trial shows cfg.presentation.n_cycles cycles.
%
%   Fields of seq (T = number of frame steps of a trial):
%     frame       1 x T   rendered frame shown at each step
%     time        1 x T   nominal onset of each step [s] from stimulus onset
%                         (cfg.presentation.trial_duration_s spread over the
%                         steps; the timing of a recording: gaze_per_step)
%     angle       1 x T   rotation angle at each step, in units of the amplitude (-1 to 1)
%     pair        1 x T   index of the frame pair that describes the change
%                         from this step to the next (see below; NaN at the last step)
%     dt                  nominal duration of a step [s]
%     duration            nominal duration of the trial [s]
%     order       1 x 61  the rendered frames sorted by rotation angle
%                         (61 60 ... 32 1 2 ... 31)
%     rank        1 x 61  position of each rendered frame in that order
%     frame_angle 1 x 61  rotation angle of each rendered frame (-1 to 1)
%     pair_frames 60 x 2  the frame pairs: pair p joins the frames at
%                         positions p and p + 1 of 'order'. Successive steps
%                         of the presentation always show neighbouring
%                         frames, so every change on the screen is one of
%                         these 60 pairs, played forward or backward.

q  = cfg.presentation.frames_per_quarter;          % 30 steps from the centre to an extreme
nf = cfg.stimulus.n_frames;                         % 61
assert(nf == 2 * q + 1, 'presentation_sequence:frames', ...
    'Expected %d frames for %d steps per quarter cycle.', 2 * q + 1, q);

% frames sorted by rotation angle; a cycle walks through them and back
order = [nf:-1:(q + 2), 1:(q + 1)];                 % 61 60 ... 32 1 2 ... 31
start = cfg.presentation.start_frame;
step  = cfg.presentation.start_direction;           % 1: toward frame 31 (right), -1: toward frame 61 (left)
assert(isscalar(start) && ismember(start, 1:nf), 'presentation_sequence:start', ...
    'cfg.presentation.start_frame must be a frame number between 1 and %d.', nf);
assert(isscalar(step) && abs(step) == 1, 'presentation_sequence:direction', ...
    'cfg.presentation.start_direction must be 1 or -1.');
r = zeros(1, 4 * q);
r(1) = find(order == start);
for k = 2:4 * q
    if r(k - 1) + step < 1 || r(k - 1) + step > nf, step = -step; end   % turn at an extreme
    r(k) = r(k - 1) + step;
end
cycle = order(r);
seq.frame = repmat(cycle, 1, cfg.presentation.n_cycles);
T = numel(seq.frame);

seq.duration = cfg.presentation.trial_duration_s;
seq.dt       = seq.duration / T;
seq.time     = (0:T - 1) * seq.dt;

% rotation angle of every rendered frame, in units of the amplitude
seq.frame_angle = zeros(1, nf);
seq.frame_angle(2:q + 1)   =  sin(pi / 2 * (1:q) / q);
seq.frame_angle(q + 2:nf)  = -sin(pi / 2 * (1:q) / q);
seq.angle = seq.frame_angle(seq.frame);

% frames sorted by angle, and the pairs of neighbours in that order
seq.order = order;
seq.rank  = zeros(1, nf);
seq.rank(seq.order) = 1:nf;
seq.pair_frames = [seq.order(1:end - 1)', seq.order(2:end)'];

r = seq.rank(seq.frame);
seq.pair = [min(r(1:end - 1), r(2:end)), NaN];
assert(all(abs(diff(r)) == 1), 'presentation_sequence:neighbours', ...
    'Successive steps must show neighbouring frames.');
end
