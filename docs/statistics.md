# The statistics

All 161 statistics, in the order of the result files. This list is the table
returned by `statistic_catalog()` (in `utils/`), which is also stored in every
result file (`G.catalog`, `Lc.catalog`).

| Scope | Number | In the global file | In a local file |
| --- | --- | --- | --- |
| `frame` | 122 | `G.frame` | yes |
| `pair` | 20 | `G.pair` | yes |
| `object` | 5 | `G.frame` | no |
| `window` | 6 | no | yes |
| `clip` | 8 | `G.clip` | no |

See the README for the units and for how the contour of the statue is kept out
of the statistics.

## Image statistics of one frame (scope `frame`)

Pooled over the whole statue (`G.frame`) and over the gaze window (`Lc`).

### `luminance` (24)

| Name | Label | Definition |
| --- | --- | --- |
| `lum_mean` | mean luminance | Mean of luminance Y over the region. |
| `lum_median` | median luminance | Median of Y. |
| `lum_sd` | SD of luminance | Standard deviation of Y. |
| `lum_skew` | luminance skewness | Skewness of Y (positive: a tail of bright pixels). |
| `lum_kurt` | luminance kurtosis | Kurtosis of Y. |
| `lum_rms_contrast` | RMS contrast | SD of Y divided by its mean. |
| `lum_p01` | luminance, 1st pct | 1st percentile of Y. |
| `lum_p10` | luminance, 10th pct | 10th percentile of Y. |
| `lum_p25` | luminance, 25th pct | 25th percentile of Y. |
| `lum_p75` | luminance, 75th pct | 75th percentile of Y. |
| `lum_p90` | luminance, 90th pct | 90th percentile of Y. |
| `lum_p99` | luminance, 99th pct | 99th percentile of Y. |
| `lum_p999` | luminance, 99.9th pct | 99.9th percentile of Y. |
| `lum_max` | maximum luminance | Maximum of Y. |
| `lum_michelson` | Michelson contrast | (P99 - P1) / (P99 + P1) of Y. |
| `lum_dark_frac` | dark fraction | Fraction of the region darker than a fifth of its mean luminance. |
| `lum_bright_frac` | bright fraction | Fraction of the region brighter than half the display white (Y > 0.5). |
| `loglum_mean` | mean log luminance | Mean of log10 Y (Y floored at cfg.stats.lum_floor). |
| `loglum_sd` | SD of log luminance | Standard deviation of log10 Y. |
| `loglum_skew` | log-luminance skewness | Skewness of log10 Y. |
| `loglum_kurt` | log-luminance kurtosis | Kurtosis of log10 Y. |
| `loglum_range` | log-luminance range | P99.9 - P1 of log10 Y. |
| `loglum_upper_tail` | upper tail | P99 - P50 of log10 Y: how far the bright pixels lie above the median. |
| `loglum_lower_tail` | lower tail | P50 - P1 of log10 Y: how far the dark pixels lie below the median. |

### `color` (41)

| Name | Label | Definition |
| --- | --- | --- |
| `lightness_mean` | lightness mean | Mean of L\* over the region. |
| `lightness_median` | lightness median | Median of L\* over the region. |
| `lightness_sd` | lightness sd | Standard deviation of L\* over the region. |
| `lightness_skew` | lightness skew | Skewness of L\* over the region. |
| `lightness_kurt` | lightness kurt | Kurtosis of L\* over the region. |
| `lightness_p01` | lightness p01 | 1st percentile of L\* over the region. |
| `lightness_p99` | lightness p99 | 99th percentile of L\* over the region. |
| `a_mean` | a mean | Mean of a\* over the region. |
| `a_median` | a median | Median of a\* over the region. |
| `a_sd` | a sd | Standard deviation of a\* over the region. |
| `a_skew` | a skew | Skewness of a\* over the region. |
| `a_kurt` | a kurt | Kurtosis of a\* over the region. |
| `a_p01` | a p01 | 1st percentile of a\* over the region. |
| `a_p99` | a p99 | 99th percentile of a\* over the region. |
| `b_mean` | b mean | Mean of b\* over the region. |
| `b_median` | b median | Median of b\* over the region. |
| `b_sd` | b sd | Standard deviation of b\* over the region. |
| `b_skew` | b skew | Skewness of b\* over the region. |
| `b_kurt` | b kurt | Kurtosis of b\* over the region. |
| `b_p01` | b p01 | 1st percentile of b\* over the region. |
| `b_p99` | b p99 | 99th percentile of b\* over the region. |
| `chroma_mean` | chroma mean | Mean of chroma C\*ab over the region. |
| `chroma_median` | chroma median | Median of chroma C\*ab over the region. |
| `chroma_sd` | chroma sd | Standard deviation of chroma C\*ab over the region. |
| `chroma_skew` | chroma skew | Skewness of chroma C\*ab over the region. |
| `chroma_kurt` | chroma kurt | Kurtosis of chroma C\*ab over the region. |
| `chroma_p01` | chroma p01 | 1st percentile of chroma C\*ab over the region. |
| `chroma_p99` | chroma p99 | 99th percentile of chroma C\*ab over the region. |
| `saturation_mean` | saturation mean | Mean of saturation (C\*ab / L\*) over the region. |
| `saturation_median` | saturation median | Median of saturation (C\*ab / L\*) over the region. |
| `saturation_sd` | saturation sd | Standard deviation of saturation (C\*ab / L\*) over the region. |
| `saturation_skew` | saturation skew | Skewness of saturation (C\*ab / L\*) over the region. |
| `saturation_kurt` | saturation kurt | Kurtosis of saturation (C\*ab / L\*) over the region. |
| `saturation_p01` | saturation p01 | 1st percentile of saturation (C\*ab / L\*) over the region. |
| `saturation_p99` | saturation p99 | 99th percentile of saturation (C\*ab / L\*) over the region. |
| `hue_mean` | mean hue | Chroma-weighted circular mean of the hue angle atan2(b\*, a\*) [deg, 0-360]. Circular: average it over time with circular statistics. |
| `hue_sd` | hue spread | Chroma-weighted circular standard deviation of the hue angle [deg]. |
| `uv_dist_mean` | mean chromatic distance | Mean distance from D65 in the CIE 1976 u'v' diagram, over pixels with Y > cfg.stats.chroma_min_lum. |
| `uv_dist_sd` | SD of chromatic distance | Standard deviation of the same distance. |
| `sat_rgb_mean` | mean RGB saturation | Mean of 1 - min(R,G,B) / max(R,G,B) of linear RGB. |
| `sat_rgb_sd` | SD of RGB saturation | Standard deviation of the same. |

### `color_luminance` (5)

| Name | Label | Definition |
| --- | --- | --- |
| `corr_lightness_saturation` | corr(L\*, saturation) | Pearson correlation across pixels between L\* and saturation. |
| `corr_lightness_chroma` | corr(L\*, chroma) | Correlation between L\* and chroma. |
| `corr_lightness_b` | corr(L\*, b\*) | Correlation between L\* and b\*. |
| `corr_lum_uv_dist` | corr(Y, u'v' distance) | Correlation between Y and the u'v' distance from D65 (pixels with Y > cfg.stats.chroma_min_lum). |
| `corr_loglum_sat_rgb` | corr(log Y, RGB saturation) | Correlation between log10 Y and the RGB saturation. |

### `contrast` (6)

| Name | Label | Definition |
| --- | --- | --- |
| `contrast_dynamic_range` | dynamic range | log10 of P99.9 / P0.1 of Y. |
| `contrast_robust_range` | robust dynamic range | log10 of the mean of the brightest 1% over the mean of the darkest 1% of the region. |
| `contrast_local` | mean absolute contrast | Mean of \|Y - mean\| / mean. |
| `contrast_local_blur` | local contrast | Mean of \|Y - local mean\| divided by the mean of the local mean; the local mean is a Gaussian average (cfg.stats.blur_deg) over object pixels only. |
| `contrast_meese_summers` | Meese-Summers contrast | Mean of \|c\|^2.4 / (1 + \|c\|^2) with c = (Y - mean) / mean. |
| `contrast_meese_summers_blur` | Meese-Summers, local | The same with c = (Y - local mean) / local mean. |

### `highlight` (19)

| Name | Label | Definition |
| --- | --- | --- |
| `hl_cover_2x` | coverage > 2 x median | Fraction of the region brighter than 2 x the median luminance of the whole object in that frame. |
| `hl_cover_4x` | coverage > 4 x median | The same for 4 x the median. |
| `hl_cover_8x` | coverage > 8 x median | The same for 8 x the median. |
| `hl_cover_16x` | coverage > 16 x median | The same for 16 x the median. |
| `hl_frac_half_max` | coverage > max / 2 | Fraction of the region brighter than half the maximum (99.9th percentile) of the whole object in that frame. |
| `hl_coverage` | highlight coverage | Fraction of the region covered by highlights. Highlights are the brightest 5% of the whole object in that frame, so this is 0.05 for the whole object and varies between gaze windows. |
| `hl_contrast` | highlight contrast | log10 of the mean luminance of the highlights in the region over the median luminance of the region. |
| `hl_n_regions` | number of highlights | Number of connected highlight regions per 10,000 region pixels. |
| `hl_mean_area` | highlight size | Mean area of the highlight regions [px]. |
| `hl_area_cv` | highlight size variation | SD of the areas of the highlight regions divided by their mean. |
| `hl_elongation` | highlight elongation | Area-weighted mean ratio of the major to the minor axis of the highlight regions of at least cfg.stats.hl_min_area px. |
| `hl_orient_coherence` | highlight alignment | Area-weighted coherence of the orientations of those regions (0 = all orientations, 1 = one orientation). |
| `hl_sharpness` | highlight sharpness | Mean gradient magnitude of L\* on the boundary pixels of the highlights [L\* per px]. |
| `hl_texture` | highlight texture | Mean gradient magnitude of L\* inside the highlights divided by the SD of L\* of the region. |
| `sat_highlight` | highlight saturation | Mean RGB saturation of the highlights. |
| `sat_body` | body saturation | Median RGB saturation of the region outside the highlights. |
| `sat_highlight_drop` | saturation drop | Body saturation minus highlight saturation (positive: highlights are less colored than the body). |
| `hl_rg` | highlight red-green | Mean of (R - G) / max(R,G,B) over the highlights. |
| `hl_yb` | highlight yellow-blue | Mean of ((R + G) / 2 - B) / max(R,G,B) over the highlights. |

### `spatial` (27)

| Name | Label | Definition |
| --- | --- | --- |
| `edge_density` | edge density | Mean gradient magnitude of L\* [L\* per px]. Every pixel of the difference stencil lies on the object. |
| `edge_density_log` | edge density (log Y) | Mean gradient magnitude of log10 Y. |
| `edge_energy` | edge energy (Y) | Mean gradient magnitude of linear luminance. |
| `grad_skew` | gradient skewness | Skewness of the gradient magnitude of L\*. |
| `grad_kurt` | gradient kurtosis | Kurtosis of the gradient magnitude of L\* (high: few sharp edges on a smooth surface). |
| `band_rms_1` | band contrast 1 | SD of band-pass image 1 of L\*/100: the difference between Gaussian blurs of successive scales (cfg.stats.band_sigma; band 1 = finest), blurred over object pixels only. |
| `band_rms_2` | band contrast 2 | SD of band-pass image 2 of L\*/100: the difference between Gaussian blurs of successive scales (cfg.stats.band_sigma; band 1 = finest), blurred over object pixels only. |
| `band_rms_3` | band contrast 3 | SD of band-pass image 3 of L\*/100: the difference between Gaussian blurs of successive scales (cfg.stats.band_sigma; band 1 = finest), blurred over object pixels only. |
| `band_rms_4` | band contrast 4 | SD of band-pass image 4 of L\*/100: the difference between Gaussian blurs of successive scales (cfg.stats.band_sigma; band 1 = finest), blurred over object pixels only. |
| `band_rms_5` | band contrast 5 | SD of band-pass image 5 of L\*/100: the difference between Gaussian blurs of successive scales (cfg.stats.band_sigma; band 1 = finest), blurred over object pixels only. |
| `band_fine_coarse` | fine / coarse contrast | log10 of (band 1 + band 2) / (band 4 + band 5). |
| `spec_slope` | spectral slope | Slope of log amplitude against log spatial frequency over cfg.stats.spec_fit, from the Fourier transform of L\*/100 minus its mean, multiplied by a window that falls to zero inside the silhouette (and at the edge of a gaze window). |
| `spec_rms_low` | contrast, low SF | RMS contrast of L\*/100 below cfg.stats.spec_bands(1) c/px. |
| `spec_rms_mid` | contrast, middle SF | RMS contrast between the two limits of cfg.stats.spec_bands. |
| `spec_rms_high` | contrast, high SF | RMS contrast above cfg.stats.spec_bands(2) c/px. |
| `spec_low_high_ratio` | low / high SF energy | log10 of the spectral energy below 1/16 c/px over the energy above. |
| `spec_orient_entropy` | orientation entropy | Entropy of the spectral energy over 18 orientation bins, divided by its maximum (1 = isotropic). |
| `spec_orient_concentration` | orientation concentration | Length of the energy-weighted mean of exp(2 i theta) over the spectrum (1 = one orientation). |
| `orient_coherence` | gradient coherence | Length of the gradient-weighted mean of exp(2 i theta) of the L\* gradient direction. |
| `orient_vh_ratio` | vertical / horizontal gradients | log10 of the summed \|vertical gradient\| over the summed \|horizontal gradient\| of L\*. |
| `pyr_level_1` | pyramid energy 1 | log10 of the mean response magnitude of level 1 of a steerable pyramid, summed over orientations (level 1 = finest, about 1/4 c/px). |
| `pyr_level_2` | pyramid energy 2 | log10 of the mean response magnitude of level 2 of a steerable pyramid, summed over orientations (level 1 = finest, about 1/8 c/px). |
| `pyr_level_3` | pyramid energy 3 | log10 of the mean response magnitude of level 3 of a steerable pyramid, summed over orientations (level 1 = finest, about 1/16 c/px). |
| `pyr_level_4` | pyramid energy 4 | log10 of the mean response magnitude of level 4 of a steerable pyramid, summed over orientations (level 1 = finest, about 1/32 c/px). |
| `pyr_fine_coarse` | pyramid fine - coarse | Level 1 minus the coarsest level (log10 units). |
| `pyr_anisotropy_fine` | anisotropy, fine | SD over orientations of the level-1 energy divided by its mean. |
| `pyr_anisotropy_coarse` | anisotropy, coarse | The same for the coarsest level. |

## Motion statistics of two successive frames (scope `pair`)

Pooled over the whole statue (`G.pair`) and over the gaze window (`Lc`). At a frame step, they describe the change from that frame to the next one shown.

### `temporal` (6)

| Name | Label | Definition |
| --- | --- | --- |
| `diff_energy` | frame difference | Mean absolute change of luminance between the two frames. |
| `diff_energy_lightness` | frame difference (L\*) | Mean absolute change of L\*. |
| `temporal_contrast` | temporal contrast | Mean absolute change of luminance divided by the mean luminance. |
| `temporal_spatial_ratio` | temporal / spatial gradient | log10 of the mean absolute change of L\* over the mean spatial gradient magnitude of L\*. |
| `decorrelation` | decorrelation | 1 minus the correlation across pixels of L\* between the two frames. |
| `hl_persistence` | highlight persistence | Overlap (Dice coefficient) of the highlight maps of the two frames. |

### `flow` (10)

| Name | Label | Definition |
| --- | --- | --- |
| `flow_speed` | flow speed | Mean magnitude of the flow [px per frame step]. |
| `flow_speed_sd` | flow speed variation | SD across pixels of the flow magnitude. |
| `flow_hl_speed` | highlight speed | Mean flow magnitude over the highlights. |
| `flow_hl_body_ratio` | highlight / body speed | log10 of the mean flow magnitude of the highlights over that of the rest of the region. |
| `flow_residual` | non-affine flow | Mean residual of an affine fit to the flow over the region, divided by the mean speed. A rigidly moving smooth surface gives a nearly affine flow. |
| `flow_hl_residual_ratio` | highlight residual | Mean residual over the highlights divided by the mean residual of the region. |
| `flow_divergence` | flow divergence | Mean absolute divergence of the flow. |
| `flow_curl` | flow curl | Mean absolute curl of the flow. |
| `flow_div_frac` | divergent fraction | Fraction of the region with \|divergence\| above cfg.flow.div_thresh. |
| `flow_dir_coherence` | direction coherence | Magnitude of the mean flow vector divided by the mean flow magnitude (1 = one direction). |

### `tracking` (4)

| Name | Label | Definition |
| --- | --- | --- |
| `track_coverage` | tracked fraction | Fraction of a grid of object points tracked from one frame to the next (Kanade-Lucas-Tomasi tracker with a forward-backward check). |
| `track_coverage_change` | coverage change | Percent decrease of the tracked fraction from one frame step to two frame steps. |
| `track_rigid_inlier` | 3-D shape reliability | Fraction of the tracked vectors that agree with one rigid 3-D motion of the whole statue (inliers of a fundamental matrix fitted by RANSAC). |
| `track_speed` | tracked speed | Mean displacement of the tracked points [px per frame step]. |

## Geometry of the silhouette (scope `object`)

Whole statue only (`G.frame`, after the image statistics).

### `geometry` (5)

| Name | Label | Definition |
| --- | --- | --- |
| `obj_area_frac` | object area | Fraction of the image covered by the statue. |
| `obj_width_deg` | object width | Width of the bounding box of the statue [deg]. |
| `obj_height_deg` | object height | Height of the bounding box [deg]. |
| `obj_centroid_x_deg` | object centre x | Horizontal position of the centroid of the statue from the image centre [deg, rightward positive]. |
| `obj_centroid_y_deg` | object centre y | Vertical position of the centroid from the image centre [deg, downward positive]. |

## Geometry of the gaze window (scope `window`)

Gaze window only (the first six statistics of `Lc`).

### `geometry` (6)

| Name | Label | Definition |
| --- | --- | --- |
| `win_coverage` | window on object | Fraction of the gaze window that lies on the interior of the statue. |
| `gaze_on_object` | gaze on object | 1 if the gaze position is on the statue, 0 otherwise. |
| `gaze_dist_to_contour_deg` | distance to contour | Distance from gaze to the nearest point of the silhouette [deg]; positive inside the statue, negative outside. |
| `gaze_x_rel` | gaze x on statue | Horizontal gaze position within the bounding box of the statue (0 = left edge, 1 = right edge). |
| `gaze_y_rel` | gaze y on statue | Vertical gaze position within the bounding box (0 = top, 1 = bottom). |
| `gaze_ecc_deg` | distance from centre | Distance from gaze to the centroid of the statue [deg]. |

## Statistics of the whole swing (scope `clip`)

Whole statue only (`G.clip`): one value per condition.

### `temporal` (8)

| Name | Label | Definition |
| --- | --- | --- |
| `pix_temporal_sd` | pixel variation | Mean over pixels of the SD of L\* across the presented frames (pixels inside the statue in every frame). |
| `pix_temporal_sd_p90` | pixel variation, 90th pct | 90th percentile over pixels of the same SD. |
| `pix_temporal_sd_bright` | pixel variation, bright | Mean of the same SD over the pixels that are highlights in the central frame. |
| `pix_temporal_sd_ratio` | bright / body variation | log10 of the bright-pixel mean over the mean of the other pixels. |
| `decorr_half` | decorrelation, half swing | 1 minus the correlation of L\* between the central frame and the frames at half the amplitude (mean of the two sides). |
| `decorr_extreme` | decorrelation, full swing | The same for the two extreme frames. |
| `hl_persistence_extreme` | highlight persistence, full swing | Overlap (Dice) of the highlight map of the central frame with those of the extreme frames. |
| `temporal_hf_share` | fast temporal energy | Share of the temporal spectral energy of L\* in the upper half of the temporal frequencies, over the presented sequence. |
