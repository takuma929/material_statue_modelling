function seq = presentation_sequence(cfg)
% PRESENTATION_SEQUENCE  Which rendered frame was on the screen at each moment.
%
%   seq = presentation_sequence(cfg) describes the sinusoidal presentation
%   of a trial. The statue swings about its central view; the 61 rendered
%   frames sample the swing at equal time steps:
%
%       frame  1        central view (angle 0)
%       frames 2 - 31   centre -> one extreme   (angle  sin(pi/2 * k/30))
%       frames 32 - 61  centre -> other extreme (angle -sin(pi/2 * k/30))
%
%   One cycle shows 1 2 ... 31 30 ... 2 1 32 ... 61 60 ... 32, that is 120
%   frame steps, and a trial shows cfg.presentation.n_cycles cycles.
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

half_a = [1:(q + 1), q:-1:2];                       % 1 2 ... 31 30 ... 2
half_b = [1, (q + 2):nf, (nf - 1):-1:(q + 2)];      % 1 32 ... 61 60 ... 32
if cfg.presentation.first_half == 1
    cycle = [half_a, half_b];
else
    cycle = [half_b, half_a];
end
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
seq.order = [nf:-1:(q + 2), 1:(q + 1)];
seq.rank  = zeros(1, nf);
seq.rank(seq.order) = 1:nf;
seq.pair_frames = [seq.order(1:end - 1)', seq.order(2:end)'];

r = seq.rank(seq.frame);
seq.pair = [min(r(1:end - 1), r(2:end)), NaN];
assert(all(abs(diff(r)) == 1), 'presentation_sequence:neighbours', ...
    'Successive steps must show neighbouring frames.');
end
