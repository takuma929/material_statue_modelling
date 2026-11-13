function make_trajectory_video(result_file, trial_numbers)
% MAKE_TRAJECTORY_VIDEO  Video of a trial with every statistic at the gaze position.
%
%   make_trajectory_video(result_file) draws each trial of a result file of
%   compute_local_statistics (results/local_statistics_<name>_r<radius>deg.mat)
%   as a video, for checking by eye that the gaze data and the statistics
%   are what they should be:
%     left    the stimulus as it was shown, with the gaze window (circle)
%             and the recent gaze path; below it the window enlarged (the
%             pixels that are not pooled are dimmed) and the rotation angle
%     right   every statistic of the window as a bar, named as in the
%             result file and colored by family. The length of a bar is the
%             value in the gaze window at this moment, on an axis whose left
%             end is the 5th and whose right end is the 95th percentile of
%             that statistic over all frame steps of the file; the white
%             tick marks, on the same axis, the value of the whole statue
%             in the same frame (if results/global_statistics.mat exists)
%
%   Statistics that measure the same quantity in the same unit share one
%   axis, so that their bars can be compared with one another: the axis
%   runs from the lowest 5th to the highest 95th percentile among them, and
%   starts at zero if they are all positive. For example, lum_p01 ...
%   lum_max, lum_mean, lum_median and lum_sd are all luminances and are
%   drawn on one luminance axis that starts at zero: a bar twice as long is
%   twice the luminance. The groups are listed in the function shared_axes
%   at the end of this file. Correlations use the fixed axis -1 to 1 and
%   relative gaze positions the fixed axis 0 to 1. Every other statistic
%   has its own axis, from its 5th to its 95th percentile.
%   make_trajectory_video(result_file, trial_numbers) draws only the listed
%   trials (their numbers in the trajectory file).
%
%   Example
%     make_trajectory_video('results/local_statistics_ABF_1_BR_gaze_trajectory_coordinates_r1.5deg.mat')
%
%   Output: results/videos/<name>_r<radius>deg_trial<N>_<condition>.mp4,
%   played at half the speed of the experiment. A trial takes about 3
%   minutes to draw. The stimulus files must be in data/MAT-images/.

project_root = fileparts(mfilename('fullpath'));
addpath(fullfile(project_root, 'utils'));
S = load(result_file, 'Lc'); Lc = S.Lc;
cfg = load_config();
cfg.window.radius_deg = Lc.radius_deg;                     % the window the statistics were computed in
check_stimuli(cfg);
col = project_colors();
seq = presentation_sequence(cfg);
T = numel(seq.frame);
[~, set_name] = fileparts(Lc.source);
if nargin < 2 || isempty(trial_numbers), trial_numbers = Lc.trials.trial'; end
SLOW = 2;                                                   % playback is this many times slower than the experiment

%% ---- scaling of the bars ---------------------------------------------------------
K = numel(Lc.names);
all_values = reshape(Lc.values, [], K);
lo = prctile(all_values, 5, 1); hi = prctile(all_values, 95, 1);
% statistics of the same quantity and unit share one axis (shared_axes)
groups = shared_axes();
for g = 1:size(groups, 1)
    in = ~cellfun(@isempty, regexp(Lc.names, groups{g, 2}, 'once'));
    if ~any(in), continue; end
    if isempty(groups{g, 3})
        lo(in) = min(lo(in), [], 'omitnan'); hi(in) = max(hi(in), [], 'omitnan');
        if lo(find(in, 1)) > 0, lo(in) = 0; end             % all positive: the axis starts at zero
    else
        lo(in) = groups{g, 3}(1); hi(in) = groups{g, 3}(2);
    end
end
span = hi - lo;
flat = ~(span > 0);                                         % a statistic that does not vary over the file
span(flat) = 1; lo(flat) = lo(flat) - 0.5;                  % is drawn as a half bar
scale = @(v) min(max((v - lo) ./ span, 0), 1);
bar_color = zeros(K, 3);
for k = 1:K, bar_color(k, :) = col.group(col.group_of(Lc.family{k}), :); end

% the whole statue, if it has been computed: for the white ticks
G = [];
gfile = fullfile(cfg.paths.results, 'global_statistics.mat');
if exist(gfile, 'file'), S = load(gfile, 'G'); G = S.G; end

%% ---- canvas (1920 x 1080 pixels) ----------------------------------------------------
Wpx = 1920; Hpx = 1080; DPI = 100;
bg = [0.07 0.07 0.08]; fg = [0.92 0.92 0.92]; dim = [0.62 0.62 0.64];
NCOL = 4; NROW = ceil(K / NCOL);                            % layout of the bars
bar_left = 668; col_w = (Wpx - 20 - bar_left) / NCOL; label_w = col_w - 112; bar_w = 100;
bar_top = 30; bar_h = Hpx - 55 - bar_top;

for trial_number = trial_numbers
    i_trial = find(Lc.trials.trial == trial_number);
    assert(isscalar(i_trial), 'make_trajectory_video:trial', 'Trial %d is not in %s.', trial_number, result_file);
    cond = char(Lc.trials.condition(i_trial));
    frames = load_frames(cfg, cond);
    masks  = load_object_masks(cfg, cond);
    gx = Lc.gaze_x(i_trial, :); gy = Lc.gaze_y(i_trial, :);
    local = reshape(Lc.values(i_trial, :, :), T, K);
    whole = nan(T, K);
    if ~isempty(G)
        c_glob = strcmp(G.conditions, cond);
        [tf, loc] = ismember(Lc.names, G.frame.names);
        whole(:, tf) = squeeze(G.frame.values(c_glob, seq.frame, loc(tf)));
        [tf, loc] = ismember(Lc.names, G.pair.names);
        ok = ~isnan(seq.pair);
        whole(ok, tf) = squeeze(G.pair.values(c_glob, seq.pair(ok), loc(tf)));
    end
    bar_local = scale(local); bar_whole = scale(whole);
    bar_whole(isnan(whole)) = NaN;

    % ---- static parts of the picture ---------------------------------------------
    fig = figure('Visible', 'off', 'Color', bg, 'Units', 'pixels', 'Position', [50 50 Wpx Hpx], ...
        'InvertHardcopy', 'off', 'PaperUnits', 'inches', 'PaperPosition', [0 0 Wpx Hpx] / DPI);
    box_ = @(l, t, w, h) [l / Wpx, 1 - (t + h) / Hpx, w / Wpx, h / Hpx];   % pixel box from the top-left corner
    font = {'FontName', 'Arial', 'Color', fg, 'Interpreter', 'none'};
    ov = axes('Parent', fig, 'Position', [0 0 1 1], 'Visible', 'off', 'XLim', [0 Wpx], 'YLim', [0 Hpx], 'YDir', 'reverse');
    hold(ov, 'on');
    text(ov, 30, 30, 'Image statistics at the gaze position', font{:}, 'FontSize', 19, 'FontWeight', 'bold');
    text(ov, 30, 58, sprintf('observer %s, condition %s, trial %d  %s', char(Lc.trials.observer(i_trial)), cond, trial_number, ...
        char(Lc.trials.task(i_trial))), font{:}, 'FontSize', 11, 'Color', dim);
    text(ov, 30, 78, sprintf('window radius %g deg  |  played at 1/%d speed', Lc.radius_deg, SLOW), font{:}, 'FontSize', 11, 'Color', dim);

    % the stimulus
    Sz = 600; xs = 30; ys = 95;
    ax_im = axes('Parent', fig, 'Position', box_(xs, ys, Sz, Sz));
    him = image(ax_im, linear_to_srgb(frames(:, :, :, 1)));
    axis(ax_im, 'image', 'off'); hold(ax_im, 'on');
    rad = cfg.window.radius_deg * cfg.display.px_per_deg;
    th = linspace(0, 2 * pi, 181);
    htrail = plot(ax_im, NaN, NaN, '-', 'Color', [1 1 1 0.45], 'LineWidth', 1.2);
    hcirc  = plot(ax_im, NaN, NaN, '-', 'Color', col.accent, 'LineWidth', 2);
    hdot   = plot(ax_im, NaN, NaN, 'o', 'MarkerSize', 4, 'MarkerFaceColor', col.accent, 'MarkerEdgeColor', 'w', 'LineWidth', 0.8);

    % the window enlarged
    Z = 300; xz = 30; yz = 745;
    text(ov, xz + Z / 2, yz - 25, 'Gaze window, enlarged', font{:}, 'FontSize', 12, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
    ax_z = axes('Parent', fig, 'Position', box_(xz, yz, Z, Z));
    r = ceil(rad);
    hz = image(ax_z, zeros(2 * r + 1, 2 * r + 1, 3));
    axis(ax_z, 'image', 'off'); hold(ax_z, 'on');
    plot(ax_z, r + 1 + rad * cos(th), r + 1 + rad * sin(th), '-', 'Color', col.accent, 'LineWidth', 2);
    hnote = text(ov, xz + Z / 2, yz + Z / 2, '', font{:}, 'FontSize', 12, 'HorizontalAlignment', 'center');

    % time, rotation angle and the key, beside the window
    xk = 362;
    htime = text(ov, xk, yz + 6, '', font{:}, 'FontSize', 12);
    time = Lc.time(i_trial, :);                             % onset of each frame step in this recording
    ax_ang = axes('Parent', fig, 'Position', box_(xk + 36, yz + 34, 240, 50), 'Color', bg, 'XColor', dim, 'YColor', dim, ...
        'FontName', 'Arial', 'FontSize', 9, 'Box', 'off', 'TickDir', 'out', 'XLim', [0 time(end)], 'YLim', [-1.25 1.25], ...
        'YTick', [-1 0 1], 'NextPlot', 'add');
    plot(ax_ang, time, seq.angle, '-', 'Color', dim, 'LineWidth', 1);
    hang = plot(ax_ang, 0, 0, 'o', 'MarkerSize', 6, 'MarkerFaceColor', fg, 'MarkerEdgeColor', 'none');
    xlabel(ax_ang, 'Time [s]', 'Color', dim, 'FontSize', 9); ylabel(ax_ang, 'Angle', 'Color', dim, 'FontSize', 9);
    for g = 1:numel(col.group_names)
        text(ov, xk, yz + 131 + (g - 1) * 19, col.group_names{g}, font{:}, 'FontSize', 11, 'Color', min(col.group(g, :) * 1.2, 1));
    end
    notes = {'Bar: value in the gaze window now', 'Bar axis: 5th to 95th percentile over this', 'recording; one axis per kind of quantity', ...
        'White tick: whole statue, same frame', 'Pixels used: on the statue, in the', ...
        sprintf('circle, >= %d px from its contour', cfg.edge.border_px)};
    note_y = yz + [249 262 275 291 307 320];
    for n = 1:numel(notes)
        text(ov, xk, note_y(n), notes{n}, font{:}, 'FontSize', 9, 'Color', dim);
    end

    % every statistic as a bar
    hbar = gobjects(1, NCOL); hwh = gobjects(1, NCOL); idx = cell(1, NCOL);
    for cidx = 1:NCOL
        idx{cidx} = (cidx - 1) * NROW + 1:min(cidx * NROW, K);
        n = numel(idx{cidx});
        x0 = bar_left + (cidx - 1) * col_w;
        ax = axes('Parent', fig, 'Position', box_(x0 + label_w + 8, bar_top, bar_w, bar_h), 'Color', [0.14 0.14 0.15], ...
            'XColor', 'none', 'YColor', 'none', 'XLim', [0 1], 'YLim', [0.4 NROW + 0.6], 'YDir', 'reverse', 'NextPlot', 'add');
        hbar(cidx) = barh(ax, 1:n, zeros(1, n), 0.7, 'FaceColor', 'flat', 'EdgeColor', 'none', 'CData', bar_color(idx{cidx}, :));
        hwh(cidx) = plot(ax, nan(1, n), 1:n, '|', 'Color', 'w', 'MarkerSize', 11, 'LineWidth', 1.5);
        for j = 1:n
            k = idx{cidx}(j);
            text(ov, x0 + label_w, bar_top + bar_h * (j - 0.4) / (NROW + 0.2), Lc.names{k}, font{:}, 'FontSize', 9.5, ...
                'HorizontalAlignment', 'right', 'Color', min(bar_color(k, :) * 1.2, 1));
        end
    end
    uistack(ov, 'top');                                     % the text is drawn above the panels

    % ---- one picture per frame step ------------------------------------------------
    if ~exist(cfg.paths.videos, 'dir'), mkdir(cfg.paths.videos); end
    stem = fullfile(cfg.paths.videos, sprintf('%s_r%gdeg_trial%d_%s', set_name, Lc.radius_deg, trial_number, cond));
    profiles = VideoWriter.getProfiles();
    if any(strcmp({profiles.Name}, 'MPEG-4'))
        vw = VideoWriter([stem '.mp4'], 'MPEG-4');
    else
        vw = VideoWriter([stem '.avi'], 'Motion JPEG AVI');   % where MPEG-4 is not available
    end
    vw.FrameRate = 1 / mean(diff(Lc.time(i_trial, :))) / SLOW;   % frame steps per second of the recording, slowed
    vw.Quality = 90;
    open(vw);
    [dx, dy] = meshgrid(-r:r);
    disk = hypot(dx, dy) <= rad;
    se = strel('disk', cfg.edge.border_px, 0);
    for j = 1:T
        f = seq.frame(j);
        rgb = linear_to_srgb(frames(:, :, :, f));
        him.CData = rgb;
        hang.XData = time(j); hang.YData = seq.angle(j);
        htime.String = sprintf('t = %.2f s    frame %d / %d', time(j), f, cfg.stimulus.n_frames);
        if isnan(gx(j))
            % no gaze at this step (blink, track loss): nothing is pooled
            hcirc.XData = NaN; hcirc.YData = NaN; hdot.XData = NaN; hdot.YData = NaN;
            hz.CData = zeros(2 * r + 1, 2 * r + 1, 3) + reshape(bg, 1, 1, 3);
            hnote.String = 'no gaze sample';
        else
            hcirc.XData = gx(j) + rad * cos(th); hcirc.YData = gy(j) + rad * sin(th);
            hdot.XData = gx(j); hdot.YData = gy(j);
            past = max(1, j - 20):j;
            htrail.XData = gx(past); htrail.YData = gy(past);
            % the window: pooled pixels at full brightness, other pixels dimmed
            cx = round(gx(j)); cy = round(gy(j));
            patch_rgb = zeros(2 * r + 1, 2 * r + 1, 3); pooled = false(2 * r + 1);
            rows = cy + (-r:r); cols = cx + (-r:r);
            okr = rows >= 1 & rows <= size(rgb, 1); okc = cols >= 1 & cols <= size(rgb, 2);
            patch_rgb(okr, okc, :) = rgb(rows(okr), cols(okc), :);
            inner = imerode(masks(:, :, f), se);
            pooled(okr, okc) = inner(rows(okr), cols(okc));
            pooled = pooled & disk;
            patch_rgb = patch_rgb .* (0.35 + 0.65 * pooled) .* disk + reshape(bg, 1, 1, 3) .* ~disk;
            hz.CData = patch_rgb;
            if isnan(local(j, find(strcmp(Lc.names, 'lum_mean'), 1)))
                hnote.String = 'window off the statue';
            else
                hnote.String = '';
            end
        end
        for cidx = 1:NCOL
            v = bar_local(j, idx{cidx}); v(isnan(v)) = 0;
            hbar(cidx).YData = v;
            hwh(cidx).XData = bar_whole(j, idx{cidx});
        end
        img = print(fig, '-RGBImage', sprintf('-r%d', DPI));
        if size(img, 1) ~= Hpx || size(img, 2) ~= Wpx, img = imresize(img, [Hpx Wpx]); end
        writeVideo(vw, img);
    end
    close(vw); close(fig);
    fprintf('Video of trial %d (%s) -> %s\n', trial_number, cond, fullfile(vw.Path, vw.Filename));
end
end

% =========================================================================
function groups = shared_axes()
% Statistics that are drawn on one common axis: {label, pattern of the
% names, fixed limits or [] for the limits of the data}. The members of a
% group measure the same quantity in the same unit.
groups = {
    'luminance (1 = display white)',          '^lum_(mean|median|sd|p01|p10|p25|p75|p90|p99|p999|max)$', []
    'log10 ratio of luminances',              '^(loglum_(sd|range|upper_tail|lower_tail)|contrast_(dynamic|robust)_range|hl_contrast)$', []
    'lightness L*',                           '^lightness_(mean|median|sd|p01|p99)$', []
    'a*, b* and chroma',                      '^(a|b|chroma)_(mean|median|sd|p01|p99)$', []
    'saturation C*ab / L*',                   '^saturation_(mean|median|sd|p01|p99)$', []
    'skewness',                               '_skew$', []
    'kurtosis',                               '_kurt$', []
    'correlation',                            '^corr_', [-1 1]
    'distance in the u''v'' diagram',          '^uv_dist_(mean|sd)$', []
    'RGB saturation',                         '^(sat_rgb_(mean|sd)|sat_highlight|sat_body|sat_highlight_drop)$', []
    'opponent chromaticity of the highlights', '^hl_(rg|yb)$', []
    'fraction of the pixels of the region',   '^(lum_(dark|bright)_frac|hl_cover_\d+x|hl_frac_half_max|hl_coverage)$', []
    'contrast to the mean',                   '^contrast_local(_blur)?$', []
    'Meese-Summers contrast',                 '^contrast_meese_summers(_blur)?$', []
    'gradient of L* [L* per px]',             '^(edge_density|hl_sharpness)$', []
    'RMS contrast of L*/100',                 '^(band_rms_\d+|spec_rms_(low|mid|high))$', []
    'log10 pyramid energy',                   '^pyr_level_\d+$', []
    'anisotropy of the pyramid',              '^pyr_anisotropy_(fine|coarse)$', []
    'speed [px per frame step]',              '^(flow_speed|flow_speed_sd|flow_hl_speed|track_speed)$', []
    'divergence and curl of the flow',        '^flow_(divergence|curl)$', []
    'gaze position within the bounding box',  '^gaze_[xy]_rel$', [0 1]
    };
end
