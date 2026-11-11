function cfg = analysis_config()
% ANALYSIS_CONFIG  Central configuration of the statue project.
%
%   cfg = analysis_config() returns every setting the pipeline uses: where
%   the stimuli and the gaze data live, how the stimulus was presented, the
%   geometry of the display, and the parameters of the image statistics.
%   Every script and helper reads its settings from here, so a change made
%   in this file applies to the whole pipeline.
%
%   VALUES TO CONFIRM against the experiment (marked "CONFIRM" below):
%     cfg.presentation.timing          how gaze time is turned into a frame
%     cfg.presentation.first_half      which half-swing was shown first
%     cfg.display.image_size_deg       visual angle of the stimulus image
%   The first two only affect the conversion of gaze samples (time ->
%   frame). The visual angle sets the size of the gaze window in pixels; of
%   the statistics of the whole statue, it enters only the four of the
%   silhouette expressed in degrees (obj_*_deg) and the two contrast
%   statistics that use a local mean over cfg.stats.blur_deg
%   (contrast_local_blur, contrast_meese_summers_blur).

cfg = struct();
cfg.root = fileparts(fileparts(mfilename('fullpath')));

%% ---- Conditions --------------------------------------------------------
% Nine conditions: three statues x three materials. A condition is named by
% two letters, statue first: 'BC' is statue B in material C.
cfg.statues         = {'B', 'H', 'P'};
cfg.materials       = {'C', 'R', 'S'};
cfg.statue_labels   = {'Statue B', 'Statue H', 'Statue P'};      % names used in figures
cfg.material_labels = {'Material C', 'Material R', 'Material S'};
[s, m] = ndgrid(1:numel(cfg.statues), 1:numel(cfg.materials));
s = s'; m = m';                                                   % statue-major order: BC BR BS HC ...
cfg.conditions = arrayfun(@(i, j) [cfg.statues{i} cfg.materials{j}], s(:), m(:), 'UniformOutput', false)';

%% ---- Stimulus files ----------------------------------------------------
% format 'mat': <dir>/<mat_pattern(condition)>, one file per condition: the
%               stimuli as shown, sRGB-encoded double images between 0 and 1.
% format 'png': <dir>/<folder_pattern(condition)>/<file_pattern(frame)>,
%               the same images rounded to 8 bits.
% utils/load_frames.m describes both. The .mat files are the reference; to
% use the PNG files instead, set format = 'png' and dir = .../PNG-images.
cfg.stimulus.format         = 'mat';
cfg.stimulus.dir            = fullfile(cfg.root, 'data', 'MAT-images');
cfg.stimulus.mat_pattern    = '%s.mat';
cfg.stimulus.mat_variable   = 'img';       % variable holding the frames ('' = the largest variable of the file)
cfg.stimulus.mat_encoding   = 'srgb';      % 'srgb' (gamma-encoded, as these files are) or 'linear'
cfg.stimulus.mat_white      = 1;           % value of the display white after decoding
cfg.stimulus.folder_pattern = 'extracted_pngs_%s';
cfg.stimulus.file_pattern   = 'frame_%02d.png';
cfg.stimulus.n_frames       = 61;          % rendered frames per condition
cfg.stimulus.image_size_px  = 1024;        % frames are square

%% ---- Presentation ------------------------------------------------------
% The 61 rendered frames sample one sinusoidal swing of the statue at equal
% time steps: frame 1 is the central view, frames 2-31 run from the centre
% to one extreme and frames 32-61 from the centre to the other extreme (the
% steps between frames shrink toward each extreme, as a sinusoid does). One
% cycle is centre -> extreme -> centre -> other extreme -> centre, that is
% 4 x 30 = 120 frame steps, and a trial shows two cycles (240 frame steps).
% See utils/presentation_sequence.m.
cfg.presentation.frames_per_quarter = 30;
cfg.presentation.n_cycles           = 2;
cfg.presentation.first_half         = 1;      % CONFIRM: 1 = frames 2-31 first, 2 = frames 32-61 first
% Timing. The gaze recordings last 13.50 to 13.57 s. How a gaze sample is
% assigned to a frame step (utils/gaze_per_step.m):
%   'recording'  the 240 frame steps are spread evenly over each recording,
%                from its first to its last sample: the recording is taken
%                to span exactly the presentation of the two cycles
%   'nominal'    every frame step lasts trial_duration_s / 240, counted
%                from the first sample of the recording
cfg.presentation.timing             = 'recording';   % CONFIRM
cfg.presentation.trial_duration_s   = 13.5;          % nominal duration of a trial [s]

%% ---- Display geometry and gaze coordinates ------------------------------
% Gaze files give the gaze position in "stimulus pixels": the frame of the
% stimulus as it was displayed, 1080 x 1080 pixels with the origin at its
% top-left corner (the 1024-px image shown enlarged to 1080 px). This was
% checked against plots of the same recordings. image_rect_px is the
% rectangle of the image in the coordinates of the gaze file,
% [left top width height]; utils/screen_to_image.m converts with it. For
% gaze in screen pixels, put the rectangle of the image on the screen here.
cfg.display.image_rect_px  = [0 0 1080 1080];
cfg.display.image_size_deg = 20;                                   % CONFIRM: visual angle of the stimulus image [deg]
cfg.display.px_per_deg     = cfg.stimulus.image_size_px / cfg.display.image_size_deg;   % image pixels per degree

%% ---- Object mask and the handling of its edge --------------------------
% The statue is rendered against a background that is exactly black. Its
% silhouette is the union over the three materials of the lit pixels (a
% statue has the same silhouette in every material, and some materials have
% black pixels inside the object). Openings through which the background is
% seen (between an arm and the body) are kept as background.
% A pixel counts as lit from one 8-bit step upward. A threshold of zero
% would not do: the renderer's pixel filter spreads values of 1e-8 to 1e-5
% over about 2 px outside the object, which are not part of it.
cfg.mask.threshold = 1 / 255;      % a pixel is lit if any sRGB-encoded channel reaches this value
cfg.mask.close_px  = 1;            % closes pinholes left by black object pixels
cfg.mask.min_area  = 200;          % connected parts smaller than this [px] are dropped
% The contour of the object against the background is not a feature of the
% material. Pixel statistics therefore leave out a band inside the
% silhouette, and spectral statistics use a window that falls smoothly to
% zero inside the silhouette (utils/object_region.m).
% Width of the band: measured from the stimuli (the mean gradient as a
% function of the distance from the silhouette). In material C the
% luminance step of the contour is over 2 px inside the silhouette. In
% materials R and S the rim of the object is black for a further 2 to 3 px,
% so the step from black to the lit surface lies deeper: the gradient peaks
% 3 to 4 px inside the silhouette (up to 7 times its interior level) and is
% back within 20% of the interior level from the 8th pixel. One band of
% 7 px is used for all materials, so that the three materials of a statue
% are measured over exactly the same pixels.
cfg.edge.border_px = 7;            % band left out of every pixel statistic
cfg.edge.taper_px  = 8;            % width of the smooth fall of the spectral window

%% ---- Gaze window (local statistics) ------------------------------------
cfg.window.radius_deg   = 1.5;     % radius of the circular window centred on gaze (default; an argument of compute_local_statistics)
cfg.window.min_coverage = 0.10;    % below this fraction of the window on the object, statistics are NaN
cfg.window.taper_frac   = 0.25;    % outer fraction of the radius over which the spectral window falls to zero
cfg.window.nfft         = 256;     % smallest FFT size of the window (zero-padded; larger windows use the next power of 2)

%% ---- Image statistics --------------------------------------------------
cfg.stats.lum_floor    = 1e-4;     % floor of luminance before the logarithm (a third of one 8-bit step)
cfg.stats.chroma_min_lum = 0.002;  % chromaticity is unreliable below this luminance (nearly black pixels)
cfg.stats.hl_fraction  = 0.05;     % highlights = brightest 5% of the object in a frame
cfg.stats.hl_min_area  = 20;       % highlight regions smaller than this [px] are left out of the shape statistics
cfg.stats.band_sigma   = [1 2 4 8 16];   % Gaussian scales of the band-pass images [px]
cfg.stats.blur_deg     = 0.5;      % scale of the local mean used by the local-contrast statistics [deg]
cfg.stats.nfft         = 1024;     % FFT size of the whole image
cfg.stats.spec_fit     = [1/64 1/4];     % range of the amplitude-spectrum slope [cycles per pixel]
cfg.stats.spec_bands   = [1/32 1/8];     % limits between low, middle and high spatial frequency [c/px]
cfg.stats.pyr_levels   = 4;        % octaves of the steerable pyramid (level 1 = finest)
cfg.stats.pyr_orient   = 4;        % orientations of the steerable pyramid
cfg.stats.min_pixels   = 200;      % fewer region pixels than this: statistics are NaN

%% ---- Motion statistics -------------------------------------------------
cfg.flow.scale        = 0.5;       % resolution at which the dense flow is estimated
cfg.flow.border_px    = 15;        % band inside the silhouette left out of the flow and tracking statistics
cfg.flow.div_thresh   = 0.05;      % |divergence| above this counts as divergent [1 / frame step]
cfg.flow.grid_px      = 8;         % spacing of the tracked points
cfg.flow.max_fb_error = 1;         % forward-backward error below which a point counts as tracked [px]
cfg.flow.ransac_px    = 1;         % inlier distance of the rigid-motion (fundamental-matrix) fit [px]

%% ---- Folders -----------------------------------------------------------
cfg.paths.trajectories = fullfile(cfg.root, 'data', 'trajectories');
cfg.paths.results      = fullfile(cfg.root, 'results');
cfg.paths.cache        = fullfile(cfg.root, 'results', 'cache');
cfg.paths.videos       = fullfile(cfg.root, 'results', 'videos');

cfg.rng_seed = 0;                  % seed of every randomized step of the analysis
end
