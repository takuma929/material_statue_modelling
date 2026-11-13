function cfg = load_config()
% LOAD_CONFIG  Read the settings of the project from config.json.
%
%   cfg = load_config() reads config.json, in the folder of the repository,
%   checks it, and returns the settings as the struct that every script and
%   helper works with. config.json is the only place where settings are
%   made; this function holds none. It only arranges them and derives what
%   follows from them (the list of conditions, the pixels per degree, the
%   full paths of the folders).
%
%   config.json explains each of its entries in its "help" entry, and so
%   does README.md. Where the entries go:
%
%     config.json                       cfg
%     eye_movement_files                cfg.run.eye_movement_files
%     window_radius_deg                 cfg.run.radius_deg (all of them),
%                                       cfg.window.radius_deg (the first)
%     make_video                        cfg.run.make_video
%     image_size_deg                    cfg.display.image_size_deg
%     start_frame                       cfg.presentation.start_frame
%     stimulus_folder, results_folder   cfg.stimulus.dir, cfg.paths.results
%     advanced.stimulus                 cfg.stimulus, cfg.statues, cfg.materials
%     advanced.presentation             cfg.presentation
%     advanced.gaze_file                cfg.display.image_rect_px
%     advanced.silhouette               cfg.mask
%     advanced.contour                  cfg.edge
%     advanced.window                   cfg.window
%     advanced.statistics               cfg.stats
%     advanced.motion                   cfg.flow
%     advanced.rng_seed                 cfg.rng_seed
%
%   A missing file, a file that is not valid JSON, a missing entry or a
%   value that cannot be used stops with a message that names the entry.

cfg = struct();
cfg.root = fileparts(fileparts(mfilename('fullpath')));
cfg.config_file = fullfile(cfg.root, 'config.json');
assert(exist(cfg.config_file, 'file') == 2, 'load_config:config', ...
    'The configuration file was not found: %s\nIt comes with the repository (config.json).', cfg.config_file);
try
    U = jsondecode(fileread(cfg.config_file));
catch err
    error('load_config:config', 'config.json could not be read as JSON (%s). Check the commas, quotes and brackets.', err.message);
end
assert(isstruct(U) && isfield(U, 'advanced') && isstruct(U.advanced), 'load_config:config', 'config.json has no entry: advanced.');
A = U.advanced;

%% ---- conditions: statue x material, statue first ('BC' = statue B in material C)
cfg.statues         = get(A, 'advanced', 'stimulus.statues', 'texts');
cfg.materials       = get(A, 'advanced', 'stimulus.materials', 'texts');
cfg.statue_labels   = strcat({'Statue '}, cfg.statues);
cfg.material_labels = strcat({'Material '}, cfg.materials);
[s, m] = ndgrid(1:numel(cfg.statues), 1:numel(cfg.materials));
s = s'; m = m';                                                   % statue-major order: BC BR BS HC ...
cfg.conditions = arrayfun(@(i, j) [cfg.statues{i} cfg.materials{j}], s(:), m(:), 'UniformOutput', false)';

%% ---- stimulus files (utils/load_frames.m)
cfg.stimulus.format         = get(A, 'advanced', 'stimulus.format', 'text', {'mat', 'png'});
cfg.stimulus.dir            = from_root(cfg.root, get(U, '', 'stimulus_folder', 'text'));
cfg.stimulus.mat_pattern    = get(A, 'advanced', 'stimulus.mat_pattern', 'text');
cfg.stimulus.mat_variable   = get(A, 'advanced', 'stimulus.mat_variable', 'text_or_empty');
cfg.stimulus.mat_encoding   = get(A, 'advanced', 'stimulus.mat_encoding', 'text', {'srgb', 'linear'});
cfg.stimulus.mat_white      = get(A, 'advanced', 'stimulus.mat_white', 'positive');
cfg.stimulus.folder_pattern = get(A, 'advanced', 'stimulus.folder_pattern', 'text');
cfg.stimulus.file_pattern   = get(A, 'advanced', 'stimulus.file_pattern', 'text');
cfg.stimulus.n_frames       = get(A, 'advanced', 'stimulus.n_frames', 'count');
cfg.stimulus.image_size_px  = get(A, 'advanced', 'stimulus.image_size_px', 'count');

%% ---- presentation (utils/presentation_sequence.m)
cfg.presentation.frames_per_quarter = get(A, 'advanced', 'presentation.frames_per_quarter', 'count');
cfg.presentation.n_cycles           = get(A, 'advanced', 'presentation.n_cycles', 'count');
cfg.presentation.start_frame        = get(U, '', 'start_frame', 'count');
cfg.presentation.start_direction    = get(A, 'advanced', 'presentation.start_direction', 'number');
cfg.presentation.trial_duration_s   = get(A, 'advanced', 'presentation.trial_duration_s', 'positive');

%% ---- display: gaze coordinates, pixels and degrees
cfg.display.image_rect_px  = get(A, 'advanced', 'gaze_file.image_rect_px', 'numbers');
assert(numel(cfg.display.image_rect_px) == 4, 'load_config:config', ...
    'advanced.gaze_file.image_rect_px in config.json must be [left, top, width, height].');
cfg.display.image_size_deg = get(U, '', 'image_size_deg', 'positive');
cfg.display.px_per_deg     = cfg.stimulus.image_size_px / cfg.display.image_size_deg;    % image pixels per degree

%% ---- silhouette and contour (utils/load_object_masks.m, utils/object_region.m)
cfg.mask.threshold = get(A, 'advanced', 'silhouette.threshold_8bit', 'positive') / 255;   % in sRGB-encoded units
cfg.mask.close_px  = get(A, 'advanced', 'silhouette.close_px', 'number');
cfg.mask.min_area  = get(A, 'advanced', 'silhouette.min_area', 'number');
cfg.edge.border_px = get(A, 'advanced', 'contour.border_px', 'number');
cfg.edge.taper_px  = get(A, 'advanced', 'contour.taper_px', 'number');

%% ---- gaze window (utils/gaze_window.m)
radii = get(U, '', 'window_radius_deg', 'positives');
cfg.window.radius_deg   = radii(1);
cfg.window.min_coverage = get(A, 'advanced', 'window.min_coverage', 'number');
cfg.window.taper_frac   = get(A, 'advanced', 'window.taper_frac', 'positive');
cfg.window.nfft         = get(A, 'advanced', 'window.nfft', 'count');

%% ---- image statistics (utils/frame_maps.m, utils/region_statistics.m)
names = {'lum_floor', 'chroma_min_lum', 'hl_fraction', 'hl_min_area', 'blur_deg', 'nfft', 'pyr_levels', 'pyr_orient', 'min_pixels'};
order = {'lum_floor', 'chroma_min_lum', 'hl_fraction', 'hl_min_area', 'band_sigma', 'blur_deg', 'nfft', 'spec_fit', 'spec_bands', ...
         'pyr_levels', 'pyr_orient', 'min_pixels'};
for k = 1:numel(order)
    if ismember(order{k}, names), kind = 'positive'; else, kind = 'positives'; end
    cfg.stats.(order{k}) = get(A, 'advanced', ['statistics.' order{k}], kind);
end

%% ---- motion statistics (utils/pair_maps.m, utils/motion_statistics.m)
order = {'scale', 'border_px', 'div_thresh', 'grid_px', 'max_fb_error', 'ransac_px'};
for k = 1:numel(order)
    cfg.flow.(order{k}) = get(A, 'advanced', ['motion.' order{k}], 'positive');
end

%% ---- folders
cfg.paths.trajectories = fullfile(cfg.root, 'data', 'trajectories');
cfg.paths.results      = from_root(cfg.root, get(U, '', 'results_folder', 'text'));
cfg.paths.cache        = fullfile(cfg.paths.results, 'cache');
cfg.paths.videos       = fullfile(cfg.paths.results, 'videos');

%% ---- the run: what compute_local_statistics does without arguments
cfg.run.eye_movement_files = get(U, '', 'eye_movement_files', 'texts');   % files or patterns (utils/list_eye_movement_files.m)
cfg.run.radius_deg         = radii;                                       % one radius or several [deg]
cfg.run.make_video         = get(U, '', 'make_video', 'logical');

cfg.rng_seed = get(A, 'advanced', 'rng_seed', 'number');
end

% =========================================================================
function v = get(S, prefix, path, kind, allowed)
% The entry 'path' (fields separated by dots) of the struct S, checked.
name = path;
if ~isempty(prefix), name = [prefix '.' path]; end
parts = strsplit(path, '.');
v = S;
for k = 1:numel(parts)
    assert(isstruct(v) && isfield(v, parts{k}), 'load_config:config', 'config.json has no entry: %s.', name);
    v = v.(parts{k});
end
number = @(x) isnumeric(x) && ~isempty(x) && all(isfinite(x(:)));
switch kind
    case 'number'
        ok = number(v) && isscalar(v); what = 'a number';
    case 'positive'
        ok = number(v) && isscalar(v) && v > 0; what = 'a positive number';
    case 'count'
        ok = number(v) && isscalar(v) && v > 0 && v == round(v); what = 'a positive whole number';
    case 'numbers'
        ok = number(v); what = 'a list of numbers'; v = v(:)';
    case 'positives'
        ok = number(v) && all(v(:) > 0); what = 'a positive number or a list of positive numbers'; v = v(:)';
    case 'logical'
        ok = islogical(v) && isscalar(v); what = 'true or false';
    case 'text'
        ok = ischar(v) && ~isempty(v); what = 'text in double quotes';
    case 'text_or_empty'
        if isempty(v), v = ''; end
        ok = ischar(v); what = 'text in double quotes';
    case 'texts'
        if ischar(v) && ~isempty(v), v = {v}; end
        ok = iscellstr(v) && ~isempty(v) && all(~cellfun(@isempty, v)); what = 'text or a list of texts, in double quotes';
        if ok, v = v(:)'; end
end
assert(ok, 'load_config:config', '%s in config.json must be %s.', name, what);
if nargin >= 5
    assert(ismember(v, allowed), 'load_config:config', '%s in config.json must be one of: %s.', name, strjoin(allowed, ', '));
end
end

function p = from_root(root, p)
% A folder of config.json: relative to the folder of the repository unless absolute.
absolute = startsWith(p, {'/', '\\', '~'}) || ~isempty(regexp(p, '^[A-Za-z]:', 'once'));
if ~absolute, p = fullfile(root, p); end
end
