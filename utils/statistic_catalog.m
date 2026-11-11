function T = statistic_catalog(scope)
% STATISTIC_CATALOG  Name, family and definition of every statistic.
%
%   T = statistic_catalog() returns a table with one row per statistic:
%     name        name used in every output file
%     family      luminance | color | color_luminance | contrast | highlight |
%                 spatial | temporal | flow | tracking | geometry
%     scope       what the statistic is computed from:
%                 'frame'   one frame, pooled over a region: the whole object
%                           or a gaze window (region_statistics)
%                 'pair'    two successive frames, pooled over a region
%                           (motion_statistics)
%                 'object'  the silhouette of the statue in one frame
%                 'window'  the position of a gaze window on the statue
%                 'clip'    the whole presented sequence of a condition
%     label       short label for figures
%     definition  how the statistic is computed
%   T = statistic_catalog(scope) returns only the rows of one scope, in the
%   order in which the computing function returns its values.
%
%   This file is the single list of the statistics: the computing functions
%   fill their output in the order given here and stop with an error if a
%   name is missing, so the catalog cannot drift from the code.
%
%   Conventions. "Region" is the set of object pixels pooled: the interior
%   of the object (cfg.edge.border_px inside the silhouette) or its part
%   inside the gaze window. Luminance Y is linear, 1 = display white. L*, a*, b* are CIELAB
%   relative to the display white. Skewness and kurtosis are the
%   standardized third and fourth moments (kurtosis of a normal
%   distribution = 3). Lengths are in pixels of the 1024-px image unless
%   the name ends in _deg; motion is per frame step of the presentation.

persistent ALL
if isempty(ALL), ALL = build(); end
T = ALL;
if nargin > 0 && ~isempty(scope)
    T = T(strcmp(T.scope, scope), :);
end
end

% =========================================================================
function T = build()
rows = {};
    function add(name, family, scope, label, definition)
        rows(end + 1, :) = {name, family, scope, label, definition};
    end

%% ---- luminance: distribution of luminance over the region ---------------
f = 'luminance'; s = 'frame';
add('lum_mean',        f, s, 'mean luminance',            'Mean of luminance Y over the region.');
add('lum_median',      f, s, 'median luminance',          'Median of Y.');
add('lum_sd',          f, s, 'SD of luminance',           'Standard deviation of Y.');
add('lum_skew',        f, s, 'luminance skewness',        'Skewness of Y (positive: a tail of bright pixels).');
add('lum_kurt',        f, s, 'luminance kurtosis',        'Kurtosis of Y.');
add('lum_rms_contrast',f, s, 'RMS contrast',              'SD of Y divided by its mean.');
add('lum_p01',         f, s, 'luminance, 1st pct',        '1st percentile of Y.');
add('lum_p10',         f, s, 'luminance, 10th pct',       '10th percentile of Y.');
add('lum_p25',         f, s, 'luminance, 25th pct',       '25th percentile of Y.');
add('lum_p75',         f, s, 'luminance, 75th pct',       '75th percentile of Y.');
add('lum_p90',         f, s, 'luminance, 90th pct',       '90th percentile of Y.');
add('lum_p99',         f, s, 'luminance, 99th pct',       '99th percentile of Y.');
add('lum_p999',        f, s, 'luminance, 99.9th pct',     '99.9th percentile of Y.');
add('lum_max',         f, s, 'maximum luminance',         'Maximum of Y.');
add('lum_michelson',   f, s, 'Michelson contrast',        '(P99 - P1) / (P99 + P1) of Y.');
add('lum_dark_frac',   f, s, 'dark fraction',             'Fraction of the region darker than a fifth of its mean luminance.');
add('lum_bright_frac', f, s, 'bright fraction',           'Fraction of the region brighter than half the display white (Y > 0.5).');
add('loglum_mean',     f, s, 'mean log luminance',        'Mean of log10 Y (Y floored at cfg.stats.lum_floor).');
add('loglum_sd',       f, s, 'SD of log luminance',       'Standard deviation of log10 Y.');
add('loglum_skew',     f, s, 'log-luminance skewness',    'Skewness of log10 Y.');
add('loglum_kurt',     f, s, 'log-luminance kurtosis',    'Kurtosis of log10 Y.');
add('loglum_range',    f, s, 'log-luminance range',       'P99.9 - P1 of log10 Y.');
add('loglum_upper_tail', f, s, 'upper tail',              'P99 - P50 of log10 Y: how far the bright pixels lie above the median.');
add('loglum_lower_tail', f, s, 'lower tail',              'P50 - P1 of log10 Y: how far the dark pixels lie below the median.');

%% ---- color: CIELAB distributions, hue, chromaticity ----------------------
f = 'color';
chan  = {'lightness', 'a', 'b', 'chroma', 'saturation'};
cname = {'L*', 'a*', 'b*', 'chroma C*ab', 'saturation (C*ab / L*)'};
summ  = {'mean', 'median', 'sd', 'skew', 'kurt', 'p01', 'p99'};
sname = {'Mean', 'Median', 'Standard deviation', 'Skewness', 'Kurtosis', '1st percentile', '99th percentile'};
for i = 1:numel(chan)
    for j = 1:numel(summ)
        add([chan{i} '_' summ{j}], f, s, [strrep(chan{i}, '_', ' ') ' ' summ{j}], ...
            sprintf('%s of %s over the region.', sname{j}, cname{i}));
    end
end
add('hue_mean',     f, s, 'mean hue',               'Chroma-weighted circular mean of the hue angle atan2(b*, a*) [deg, 0-360]. Circular: average it over time with circular statistics.');
add('hue_sd',       f, s, 'hue spread',             'Chroma-weighted circular standard deviation of the hue angle [deg].');
add('uv_dist_mean', f, s, 'mean chromatic distance','Mean distance from D65 in the CIE 1976 u''v'' diagram, over pixels with Y > cfg.stats.chroma_min_lum.');
add('uv_dist_sd',   f, s, 'SD of chromatic distance','Standard deviation of the same distance.');
add('sat_rgb_mean', f, s, 'mean RGB saturation',    'Mean of 1 - min(R,G,B) / max(R,G,B) of linear RGB.');
add('sat_rgb_sd',   f, s, 'SD of RGB saturation',   'Standard deviation of the same.');

%% ---- color_luminance: how color varies with luminance --------------------
f = 'color_luminance';
add('corr_lightness_saturation', f, s, 'corr(L*, saturation)', 'Pearson correlation across pixels between L* and saturation.');
add('corr_lightness_chroma',     f, s, 'corr(L*, chroma)',     'Correlation between L* and chroma.');
add('corr_lightness_b',          f, s, 'corr(L*, b*)',         'Correlation between L* and b*.');
add('corr_lum_uv_dist',          f, s, 'corr(Y, u''v'' distance)', 'Correlation between Y and the u''v'' distance from D65 (pixels with Y > cfg.stats.chroma_min_lum).');
add('corr_loglum_sat_rgb',       f, s, 'corr(log Y, RGB saturation)', 'Correlation between log10 Y and the RGB saturation.');

%% ---- contrast: global contrast estimators (Harvey & Smithson, 2021) ------
f = 'contrast';
add('contrast_dynamic_range',     f, s, 'dynamic range',        'log10 of P99.9 / P0.1 of Y.');
add('contrast_robust_range',      f, s, 'robust dynamic range', 'log10 of the mean of the brightest 1% over the mean of the darkest 1% of the region.');
add('contrast_local',             f, s, 'mean absolute contrast','Mean of |Y - mean| / mean.');
add('contrast_local_blur',        f, s, 'local contrast',       'Mean of |Y - local mean| divided by the mean of the local mean; the local mean is a Gaussian average (cfg.stats.blur_deg) over object pixels only.');
add('contrast_meese_summers',     f, s, 'Meese-Summers contrast','Mean of |c|^2.4 / (1 + |c|^2) with c = (Y - mean) / mean.');
add('contrast_meese_summers_blur',f, s, 'Meese-Summers, local', 'The same with c = (Y - local mean) / local mean.');

%% ---- highlight: coverage, shape, sharpness and color of the highlights ---
f = 'highlight';
add('hl_cover_2x',   f, s, 'coverage > 2 x median',  'Fraction of the region brighter than 2 x the median luminance of the whole object in that frame.');
add('hl_cover_4x',   f, s, 'coverage > 4 x median',  'The same for 4 x the median.');
add('hl_cover_8x',   f, s, 'coverage > 8 x median',  'The same for 8 x the median.');
add('hl_cover_16x',  f, s, 'coverage > 16 x median', 'The same for 16 x the median.');
add('hl_frac_half_max', f, s, 'coverage > max / 2',  'Fraction of the region brighter than half the maximum (99.9th percentile) of the whole object in that frame.');
add('hl_coverage',   f, s, 'highlight coverage',     'Fraction of the region covered by highlights. Highlights are the brightest 5% of the whole object in that frame, so this is 0.05 for the whole object and varies between gaze windows.');
add('hl_contrast',   f, s, 'highlight contrast',     'log10 of the mean luminance of the highlights in the region over the median luminance of the region.');
add('hl_n_regions',  f, s, 'number of highlights',   'Number of connected highlight regions per 10,000 region pixels.');
add('hl_mean_area',  f, s, 'highlight size',         'Mean area of the highlight regions [px].');
add('hl_area_cv',    f, s, 'highlight size variation','SD of the areas of the highlight regions divided by their mean.');
add('hl_elongation', f, s, 'highlight elongation',   'Area-weighted mean ratio of the major to the minor axis of the highlight regions of at least cfg.stats.hl_min_area px.');
add('hl_orient_coherence', f, s, 'highlight alignment', 'Area-weighted coherence of the orientations of those regions (0 = all orientations, 1 = one orientation).');
add('hl_sharpness',  f, s, 'highlight sharpness',    'Mean gradient magnitude of L* on the boundary pixels of the highlights [L* per px].');
add('hl_texture',    f, s, 'highlight texture',      'Mean gradient magnitude of L* inside the highlights divided by the SD of L* of the region.');
add('sat_highlight', f, s, 'highlight saturation',   'Mean RGB saturation of the highlights.');
add('sat_body',      f, s, 'body saturation',        'Median RGB saturation of the region outside the highlights.');
add('sat_highlight_drop', f, s, 'saturation drop',   'Body saturation minus highlight saturation (positive: highlights are less colored than the body).');
add('hl_rg',         f, s, 'highlight red-green',    'Mean of (R - G) / max(R,G,B) over the highlights.');
add('hl_yb',         f, s, 'highlight yellow-blue',  'Mean of ((R + G) / 2 - B) / max(R,G,B) over the highlights.');

%% ---- spatial: edges, spatial frequency and orientation -------------------
f = 'spatial';
add('edge_density',     f, s, 'edge density',          'Mean gradient magnitude of L* [L* per px]. Every pixel of the difference stencil lies on the object.');
add('edge_density_log', f, s, 'edge density (log Y)',  'Mean gradient magnitude of log10 Y.');
add('edge_energy',      f, s, 'edge energy (Y)',       'Mean gradient magnitude of linear luminance.');
add('grad_skew',        f, s, 'gradient skewness',     'Skewness of the gradient magnitude of L*.');
add('grad_kurt',        f, s, 'gradient kurtosis',     'Kurtosis of the gradient magnitude of L* (high: few sharp edges on a smooth surface).');
for k = 1:5
    add(sprintf('band_rms_%d', k), f, s, sprintf('band contrast %d', k), ...
        sprintf('SD of band-pass image %d of L*/100: the difference between Gaussian blurs of successive scales (cfg.stats.band_sigma; band 1 = finest), blurred over object pixels only.', k));
end
add('band_fine_coarse', f, s, 'fine / coarse contrast','log10 of (band 1 + band 2) / (band 4 + band 5).');
add('spec_slope',       f, s, 'spectral slope',        'Slope of log amplitude against log spatial frequency over cfg.stats.spec_fit, from the Fourier transform of L*/100 minus its mean, multiplied by a window that falls to zero inside the silhouette (and at the edge of a gaze window).');
add('spec_rms_low',     f, s, 'contrast, low SF',      'RMS contrast of L*/100 below cfg.stats.spec_bands(1) c/px.');
add('spec_rms_mid',     f, s, 'contrast, middle SF',   'RMS contrast between the two limits of cfg.stats.spec_bands.');
add('spec_rms_high',    f, s, 'contrast, high SF',     'RMS contrast above cfg.stats.spec_bands(2) c/px.');
add('spec_low_high_ratio', f, s, 'low / high SF energy', 'log10 of the spectral energy below 1/16 c/px over the energy above.');
add('spec_orient_entropy', f, s, 'orientation entropy', 'Entropy of the spectral energy over 18 orientation bins, divided by its maximum (1 = isotropic).');
add('spec_orient_concentration', f, s, 'orientation concentration', 'Length of the energy-weighted mean of exp(2 i theta) over the spectrum (1 = one orientation).');
add('orient_coherence', f, s, 'gradient coherence',    'Length of the gradient-weighted mean of exp(2 i theta) of the L* gradient direction.');
add('orient_vh_ratio',  f, s, 'vertical / horizontal gradients', 'log10 of the summed |vertical gradient| over the summed |horizontal gradient| of L*.');
for k = 1:4
    add(sprintf('pyr_level_%d', k), f, s, sprintf('pyramid energy %d', k), ...
        sprintf('log10 of the mean response magnitude of level %d of a steerable pyramid, summed over orientations (level 1 = finest, about 1/%d c/px).', k, 2^(k + 1)));
end
add('pyr_fine_coarse',       f, s, 'pyramid fine - coarse', 'Level 1 minus the coarsest level (log10 units).');
add('pyr_anisotropy_fine',   f, s, 'anisotropy, fine',      'SD over orientations of the level-1 energy divided by its mean.');
add('pyr_anisotropy_coarse', f, s, 'anisotropy, coarse',    'The same for the coarsest level.');

%% ---- temporal: change of the image between two successive frames ---------
f = 'temporal'; s = 'pair';
add('diff_energy',            f, s, 'frame difference',       'Mean absolute change of luminance between the two frames.');
add('diff_energy_lightness',  f, s, 'frame difference (L*)',  'Mean absolute change of L*.');
add('temporal_contrast',      f, s, 'temporal contrast',      'Mean absolute change of luminance divided by the mean luminance.');
add('temporal_spatial_ratio', f, s, 'temporal / spatial gradient', 'log10 of the mean absolute change of L* over the mean spatial gradient magnitude of L*.');
add('decorrelation',          f, s, 'decorrelation',          '1 minus the correlation across pixels of L* between the two frames.');
add('hl_persistence',         f, s, 'highlight persistence',  'Overlap (Dice coefficient) of the highlight maps of the two frames.');

%% ---- flow: dense optical flow (Farneback) between the two frames ---------
f = 'flow';
add('flow_speed',             f, s, 'flow speed',             'Mean magnitude of the flow [px per frame step].');
add('flow_speed_sd',          f, s, 'flow speed variation',   'SD across pixels of the flow magnitude.');
add('flow_hl_speed',          f, s, 'highlight speed',        'Mean flow magnitude over the highlights.');
add('flow_hl_body_ratio',     f, s, 'highlight / body speed', 'log10 of the mean flow magnitude of the highlights over that of the rest of the region.');
add('flow_residual',          f, s, 'non-affine flow',        'Mean residual of an affine fit to the flow over the region, divided by the mean speed. A rigidly moving smooth surface gives a nearly affine flow.');
add('flow_hl_residual_ratio', f, s, 'highlight residual',     'Mean residual over the highlights divided by the mean residual of the region.');
add('flow_divergence',        f, s, 'flow divergence',        'Mean absolute divergence of the flow.');
add('flow_curl',              f, s, 'flow curl',              'Mean absolute curl of the flow.');
add('flow_div_frac',          f, s, 'divergent fraction',     'Fraction of the region with |divergence| above cfg.flow.div_thresh.');
add('flow_dir_coherence',     f, s, 'direction coherence',    'Magnitude of the mean flow vector divided by the mean flow magnitude (1 = one direction).');

%% ---- tracking: optic-flow cues of Doerschner et al. (2011) ---------------
f = 'tracking';
add('track_coverage',        f, s, 'tracked fraction',       'Fraction of a grid of object points tracked from one frame to the next (Kanade-Lucas-Tomasi tracker with a forward-backward check).');
add('track_coverage_change', f, s, 'coverage change',        'Percent decrease of the tracked fraction from one frame step to two frame steps.');
add('track_rigid_inlier',    f, s, '3-D shape reliability',  'Fraction of the tracked vectors that agree with one rigid 3-D motion of the whole statue (inliers of a fundamental matrix fitted by RANSAC).');
add('track_speed',           f, s, 'tracked speed',          'Mean displacement of the tracked points [px per frame step].');

%% ---- geometry of the silhouette (whole image) ----------------------------
f = 'geometry'; s = 'object';
add('obj_area_frac',      f, s, 'object area',     'Fraction of the image covered by the statue.');
add('obj_width_deg',      f, s, 'object width',    'Width of the bounding box of the statue [deg].');
add('obj_height_deg',     f, s, 'object height',   'Height of the bounding box [deg].');
add('obj_centroid_x_deg', f, s, 'object centre x', 'Horizontal position of the centroid of the statue from the image centre [deg, rightward positive].');
add('obj_centroid_y_deg', f, s, 'object centre y', 'Vertical position of the centroid from the image centre [deg, downward positive].');

%% ---- geometry of a gaze window --------------------------------------------
s = 'window';
add('win_coverage',             f, s, 'window on object',    'Fraction of the gaze window that lies on the interior of the statue.');
add('gaze_on_object',           f, s, 'gaze on object',      '1 if the gaze position is on the statue, 0 otherwise.');
add('gaze_dist_to_contour_deg', f, s, 'distance to contour', 'Distance from gaze to the nearest point of the silhouette [deg]; positive inside the statue, negative outside.');
add('gaze_x_rel',               f, s, 'gaze x on statue',    'Horizontal gaze position within the bounding box of the statue (0 = left edge, 1 = right edge).');
add('gaze_y_rel',               f, s, 'gaze y on statue',    'Vertical gaze position within the bounding box (0 = top, 1 = bottom).');
add('gaze_ecc_deg',             f, s, 'distance from centre','Distance from gaze to the centroid of the statue [deg].');

%% ---- clip: the whole presented sequence of a condition --------------------
f = 'temporal'; s = 'clip';
add('pix_temporal_sd',        f, s, 'pixel variation',           'Mean over pixels of the SD of L* across the presented frames (pixels inside the statue in every frame).');
add('pix_temporal_sd_p90',    f, s, 'pixel variation, 90th pct', '90th percentile over pixels of the same SD.');
add('pix_temporal_sd_bright', f, s, 'pixel variation, bright',   'Mean of the same SD over the pixels that are highlights in the central frame.');
add('pix_temporal_sd_ratio',  f, s, 'bright / body variation',   'log10 of the bright-pixel mean over the mean of the other pixels.');
add('decorr_half',            f, s, 'decorrelation, half swing', '1 minus the correlation of L* between the central frame and the frames at half the amplitude (mean of the two sides).');
add('decorr_extreme',         f, s, 'decorrelation, full swing', 'The same for the two extreme frames.');
add('hl_persistence_extreme', f, s, 'highlight persistence, full swing', 'Overlap (Dice) of the highlight map of the central frame with those of the extreme frames.');
add('temporal_hf_share',      f, s, 'fast temporal energy',      'Share of the temporal spectral energy of L* in the upper half of the temporal frequencies, over the presented sequence.');

T = cell2table(rows, 'VariableNames', {'name', 'family', 'scope', 'label', 'definition'});
assert(numel(unique(T.name)) == height(T), 'statistic_catalog:duplicate', 'Statistic names must be unique.');
end
