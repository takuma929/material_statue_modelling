function trials = load_trajectories(file, cfg)
% LOAD_TRAJECTORIES  Read eye movements from a csv file.
%
%   trials = load_trajectories(file, cfg) reads a gaze file and returns one
%   element of a struct array per trial, with the gaze position converted
%   to pixels of the 1024-px stimulus image. Two layouts are recognized by
%   their column names.
%
%   1. One recording per file (the files of this experiment), columns
%        Timestamp_ms   time stamp of the eye tracker [ms] (not used)
%        Time_sec       time from the start of the recording [s]
%        Gaze_X, Gaze_Y gaze position in stimulus pixels: the frame of the
%                       displayed stimulus, 1080 x 1080 with the origin at
%                       its top-left corner (cfg.display.image_rect_px);
%                       NaN for missing samples (blinks)
%        EventLabel     event label of the sample (optional; kept as given)
%      The file holds one trial. Its condition, observer and number are
%      read from the file name, whose parts are separated by underscores:
%      the part that is a condition (BC, BR, ..., PS), the first part
%      (observer) and the part that is a number (the question asked), in
%      any order: ABF_1_BR_gaze_trajectory_coordinates.csv is observer
%      ABF, question 1, condition BR.
%
%   2. Several trials in one table, already in image pixels, columns
%        trial, observer, condition, task, time_s, x_px, y_px
%      (trial: a number that identifies the trial; condition: e.g. BC;
%      x_px, y_px: pixels of the 1024-px image, (1, 1) = centre of the
%      top-left pixel).
%
%   Fields of trials(i): trial, observer, condition, task; the samples t
%   [s], x, y [image pixels] as column vectors sorted by time; and event
%   (the event labels, empty if the file has none).

T = readtable(file, 'TextType', 'string');
cols = T.Properties.VariableNames;
trials = struct('trial', {}, 'observer', {}, 'condition', {}, 'task', {}, 't', {}, 'x', {}, 'y', {}, 'event', {});

if all(ismember({'Time_sec', 'Gaze_X', 'Gaze_Y'}, cols))
    %% ---- layout 1: one recording, described by the file name -------------
    [~, name] = fileparts(file);
    parts = strsplit(name, '_');
    is_cond = ismember(parts, cfg.conditions);
    assert(any(is_cond), 'load_trajectories:name', ...
        'The name of %s does not contain a condition (one of %s).', file, strjoin(cfg.conditions, ', '));
    number = str2double(parts);
    k = find(~isnan(number), 1);
    [x, y] = screen_to_image(T.Gaze_X, T.Gaze_Y, cfg);
    [t, order] = sort(T.Time_sec);
    trials(1).trial     = 1;
    trials(1).observer  = parts{1};
    trials(1).condition = parts{find(is_cond, 1)};
    trials(1).task      = '';
    if ~isempty(k)
        trials(1).trial = number(k);
        trials(1).task  = sprintf('question %d', number(k));
    end
    trials(1).t = t; trials(1).x = x(order); trials(1).y = y(order);
    trials(1).event = [];
    if ismember('EventLabel', cols), trials(1).event = T.EventLabel(order); end
else
    %% ---- layout 2: a table of several trials ------------------------------
    need = {'trial', 'observer', 'condition', 'task', 'time_s', 'x_px', 'y_px'};
    missing = setdiff(need, cols);
    assert(isempty(missing), 'load_trajectories:columns', ...
        'Columns of %s are not recognized. Expected Time_sec, Gaze_X, Gaze_Y, or: %s (missing: %s).', ...
        file, strjoin(need, ', '), strjoin(missing, ', '));
    [g, ids] = findgroups(T.trial);
    for k = 1:numel(ids)
        rows = find(g == k);
        [~, order] = sort(T.time_s(rows));
        rows = rows(order);
        trials(k).trial     = ids(k);
        trials(k).observer  = char(string(T.observer(rows(1))));
        trials(k).condition = char(string(T.condition(rows(1))));
        trials(k).task      = char(string(T.task(rows(1))));
        trials(k).t = T.time_s(rows);
        trials(k).x = T.x_px(rows);
        trials(k).y = T.y_px(rows);
        trials(k).event = [];
    end
end
end
