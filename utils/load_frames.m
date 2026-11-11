function frames = load_frames(cfg, condition, frame_idx)
% LOAD_FRAMES  Rendered frames of one condition as linear RGB.
%
%   frames = load_frames(cfg, condition) returns the frames of a condition
%   (for example 'BC') as a single array H x W x 3 x N in linear RGB with
%   the primaries of sRGB, scaled so that 1 is the display white.
%   frames = load_frames(cfg, condition, frame_idx) returns only the listed
%   frames (for example 1, or [1 31 61]).
%
%   This is the only function that touches the stimulus files. Two formats
%   are supported, selected by cfg.stimulus.format:
%
%   'mat'  one file per condition, <cfg.stimulus.dir>/<condition>.mat (the
%          stimuli as they were shown). The variable 'img' is a 1 x 61 cell
%          array of 1024 x 1024 x 3 double images, sRGB-encoded between 0
%          and 1 (the 8-bit PNG files are these images rounded to 256
%          levels). The sRGB transfer function is inverted to obtain linear
%          RGB. Other layouts are accepted as well: an H x W x 3 x N or
%          H x W x N x 3 array, integer data (scaled by the maximum of the
%          class), and linear data (cfg.stimulus.mat_encoding = 'linear').
%          If cfg.stimulus.mat_variable is empty, the variable that holds
%          the most data is used.
%
%   'png'  8-bit sRGB images, one file per frame:
%          <cfg.stimulus.dir>/extracted_pngs_<condition>/frame_<NN>.png
%
%   A .mat file cannot be read in part, and loading one takes a few
%   seconds, so the frames of the condition read last are kept in memory
%   (about 0.8 GB): repeated calls for the same condition are immediate.
%   The scripts that use a parallel pool load a condition once and hand
%   the frames to the workers, so that the workers never hold a copy each.

persistent CACHE                                   % frames of the condition read last
if nargin < 3 || isempty(frame_idx), frame_idx = 1:cfg.stimulus.n_frames; end

switch lower(cfg.stimulus.format)
    case 'png'
        folder = fullfile(cfg.stimulus.dir, sprintf(cfg.stimulus.folder_pattern, condition));
        for k = 1:numel(frame_idx)
            file = fullfile(folder, sprintf(cfg.stimulus.file_pattern, frame_idx(k)));
            img = imread(file);
            if size(img, 3) == 1, img = repmat(img, 1, 1, 3); end
            img = im2single(img(:, :, 1:3));
            if k == 1
                frames = zeros([size(img), numel(frame_idx)], 'single');
            end
            frames(:, :, :, k) = srgb_to_linear(img);
        end
    case 'mat'
        file = fullfile(cfg.stimulus.dir, sprintf(cfg.stimulus.mat_pattern, condition));
        if isempty(CACHE) || ~strcmp(CACHE.file, file)
            CACHE = [];                            % release the previous condition before reading the next
            CACHE.frames = read_mat(cfg, file);
            CACHE.file = file;
        end
        frames = CACHE.frames(:, :, :, frame_idx);
    otherwise
        error('load_frames:format', 'cfg.stimulus.format must be ''mat'' or ''png''.');
end
end

% =========================================================================
function frames = read_mat(cfg, file)
% Frames of one condition from a .mat file, as linear RGB H x W x 3 x N.
name = cfg.stimulus.mat_variable;
if isempty(name)
    % take the variable that holds the most data
    info = whos('-file', file);
    ok = ismember({info.class}, {'double', 'single', 'uint8', 'uint16', 'cell'});
    info = info(ok);
    [~, i] = max([info.bytes]);
    name = info(i).name;
end
L = load(file, name);
data = L.(name);
clear L
if iscell(data)
    % cell array of H x W x 3 frames: convert one frame at a time, so that
    % the double-precision data and the result never coexist in full
    frames = zeros([size(data{1}), numel(data)], 'single');
    for k = 1:numel(data)
        frames(:, :, :, k) = decode(data{k}, cfg);
        data{k} = [];
    end
else
    if size(data, 3) ~= 3 && size(data, 4) == 3
        data = permute(data, [1 2 4 3]);          % H x W x N x 3 -> H x W x 3 x N
    end
    frames = decode(data, cfg);
end
assert(size(frames, 3) == 3, 'load_frames:layout', ...
    'Variable %s of %s is not an RGB image sequence.', name, file);
end

function lin = decode(data, cfg)
% Stored values -> linear RGB with 1 = display white.
if isinteger(data)
    lin = single(data) / single(intmax(class(data)));
else
    lin = single(data);
end
if strcmpi(cfg.stimulus.mat_encoding, 'srgb')
    lin = srgb_to_linear(lin);
end
lin = lin / cfg.stimulus.mat_white;
end

function lin = srgb_to_linear(v)
% Inverse of the sRGB transfer function (IEC 61966-2-1).
lin = v / 12.92;
hi = v > 0.04045;
lin(hi) = ((v(hi) + 0.055) / 1.055) .^ 2.4;
end
