# material_statue_modelling

Image and video statistics of rendered statues, computed over the whole statue
and around the gaze position of an observer. All code is MATLAB.

![The nine conditions, three statues in three materials, and five views of one statue across its swing](docs/stimuli.jpg)

*The stimuli: three statues in three materials. In a trial the statue swings
sinusoidally for two cycles, from the left to the right and back; the 240 frame
steps of a trial are drawn from 61 rendered frames.*

![Overview of the statistics: one panel per kind of statistic](docs/statistics_overview.jpg)

*The statistics. Each panel shows one kind of statistic at one moment of one
trial: the whole statue with the gaze window (circle) on the left, the window
enlarged on the right. The names in bold are the names in the result files.
[docs/statistics.md](docs/statistics.md) lists all 161 statistics with their
definitions.*

## Contents

1. [What the repository does](#1-what-the-repository-does)
2. [Requirements](#2-requirements)
3. [Quick start](#3-quick-start)
4. [The configuration file](#4-the-configuration-file)
5. [Step by step](#5-step-by-step)
6. [The eye-movement file](#6-the-eye-movement-file)
7. [Reading the results](#7-reading-the-results)
8. [The check video](#8-the-check-video)
9. [The experiment: visual angle and presentation](#9-the-experiment-visual-angle-and-presentation)
10. [The statistics](#10-the-statistics)
11. [Running time, memory and common problems](#11-running-time-memory-and-common-problems)
12. [Files](#12-files)

## 1. What the repository does

In the experiment, observers viewed a rendered statue in one of nine conditions
(three statues: B, H, P; three materials: C, R, S). The statue swung
sinusoidally about its central view for two cycles in about 13.5 s (to the
right, then back to the left) while the observers answered questions about it,
and their eye movements were recorded with an EyeLink.

The repository computes a broad set of statistics of those stimuli (luminance,
color, contrast, highlights, spatial structure, motion) in two ways:

* **global**: over the whole statue, for every frame of every condition. No
  gaze data are needed.
* **local**: inside a circular window centred on the gaze position, for every
  moment of a recorded eye movement. The radius of the window is an argument,
  in degrees of visual angle.

Both use the same code: a local value is the global statistic restricted to the
pixels of the window, so the two are directly comparable. Only pixels of the
statue enter a statistic; the black background and the contour of the statue
are left out (section 10).

| Script | Input | Output |
| --- | --- | --- |
| `compute_global_statistics` | the nine stimulus files | `results/global_statistics.mat` (all conditions and frames in one file) |
| `compute_local_statistics` | the eye-movement files and the radius of the window named in `config.json` | `results/local_statistics_<name>_r<radius>deg.mat` (one file per recording) |
| `make_trajectory_video(result_file)` | a local result file | a video of the trial with every statistic, for checking by eye (optional) |
| `demo` | everything as set in `config.json` | all of the above |

What is processed and how is set in one file, [`config.json`](config.json): the
eye-movement files, the radius of the window, whether videos are made, and the
visual angle of the stimulus (section 4).

## 2. Requirements

* MATLAB (developed and tested with R2025b)
* Image Processing Toolbox, Computer Vision Toolbox, Statistics and Machine
  Learning Toolbox
* Parallel Computing Toolbox (optional; without it the loops run serially and
  take several times longer)
* The nine stimulus files (not part of the repository; see step 1)

## 3. Quick start

1. Put the nine stimulus files in `data/MAT-images/` (step 1 below).
2. In MATLAB, make the folder of the repository the current folder.
3. Run

```matlab
demo
```

This computes the statistics of the whole statue, then the statistics around
the gaze position for the eye-movement files named in `config.json`, and makes
a video of each trial. With the `config.json` of the repository, these are the
three example recordings in `data/trajectories/` and a window of radius 1.5 deg
(about 15 minutes the first time with a parallel pool). The output appears in
`results/`.

To process your own recordings, put the csv files in `data/trajectories/` (or
name them in `config.json`) and run `demo` again.

## 4. The configuration file

[`config.json`](config.json), in the folder of the repository, holds every
setting, and it is the only place where settings are made. Edit it with any
text editor; the scripts read it every time they start. No script needs to be
changed to process other files or to use another window.

The entries at the top are the ones that change from one run to the next:

```json
{
  "eye_movement_files": ["data/trajectories/*.csv"],
  "window_radius_deg": 1.5,
  "make_video": true,

  "image_size_deg": 27.6,
  "start_frame": 61,

  "stimulus_folder": "data/MAT-images",
  "results_folder": "results",

  "advanced": { ... }
}
```

| Entry | Meaning |
| --- | --- |
| `eye_movement_files` | The eye-movement files to process: a list of csv files. Each item is a file name or a pattern with `*` (every file that matches). Paths are relative to the folder of the repository, or absolute. |
| `window_radius_deg` | Radius of the circular window around the gaze position, in degrees of visual angle. A list, for example `[1, 1.5, 2]`, computes the statistics once per radius. |
| `make_video` | `true`: also make a video of every trial (about 2 minutes per trial). `false`: statistics only. |
| `image_size_deg` | Visual angle that the stimulus image spans on the display, in degrees (section 9). |
| `start_frame` | Rendered frame shown first in a trial: 61 = extreme on the left, as in the experiment (section 9). |
| `stimulus_folder` | Folder that holds the nine stimulus files. |
| `results_folder` | Folder in which the results and the videos are written. |

Some examples:

```json
"eye_movement_files": ["data/trajectories/ABF_1_BR_gaze_trajectory_coordinates.csv"]
```

processes one recording;

```json
"eye_movement_files": ["data/trajectories/ABF_*.csv", "/path/to/more_recordings/*.csv"],
"window_radius_deg": [1, 1.5, 2],
"make_video": false
```

processes every recording of observer ABF and every csv file of a second
folder, with three sizes of window and without videos.

**`advanced`** holds the parameters of the analysis itself. They rarely need to
change, and a change of any of them changes the statistics:

| Group | What it sets |
| --- | --- |
| `stimulus` | the letters of the statues and materials, the number and size of the frames, the format of the stimulus files |
| `presentation` | the number of frame steps and cycles of a trial, its nominal duration |
| `gaze_file` | the rectangle that the image occupies in the coordinates of the gaze files |
| `silhouette` | the threshold above which a pixel belongs to the statue |
| `contour` | the width of the band left out at the contour of the statue (section 10) |
| `window` | the smallest part of a gaze window that must lie on the statue, the taper of the window |
| `statistics` | the floors, the fraction of pixels that are highlights, the scales of the filters, the ranges of spatial frequency |
| `motion` | the parameters of the optical flow and of the tracked points |
| `rng_seed` | the seed of every randomized step |

The file explains every entry, including each one of `advanced`, in its `help`
entry at the end.

JSON is strict about punctuation: text goes in double quotes, items are
separated by commas, and there is no comma after the last item. A file that
cannot be read, a missing entry, or an entry with a value that cannot be used
stops the scripts with a message that names the entry.

## 5. Step by step

### Step 1. Put the stimuli in place

The stimulus files are not part of this repository. Put **all nine .mat files**
in the folder `data/MAT-images/`:

```
data/MAT-images/BC.mat   BR.mat   BS.mat
                HC.mat   HR.mat   HS.mat
                PC.mat   PR.mat   PS.mat
```

The file name is the condition: statue (B, H, P) followed by material (C, R,
S). Each file holds one variable, `img`: a 1 x 61 cell array of 1024 x 1024 x 3
images (double, sRGB-encoded, between 0 and 1), one per rendered frame. The
scripts stop with a message that names the missing files if the folder is
incomplete.

### Step 2. Statistics of the whole statue

```matlab
compute_global_statistics
```

This computes every statistic for all nine conditions and all 61 frames and
writes one file, `results/global_statistics.mat` (about 6 minutes with a
parallel pool). Run it once; it does not depend on the gaze data.

### Step 3. Statistics around the gaze position

```matlab
compute_local_statistics
```

This processes every eye-movement file named in `config.json`
(`eye_movement_files`; format of the files in section 6), with the window given
there (`window_radius_deg`). The default radius of 1.5 deg is a window 3 deg
across: 111 of the 1024 pixels of the image, which spans 27.6 deg.

Each recording gives one file,
`results/local_statistics_<name>_r<radius>deg.mat`, where `<name>` is the name
of the eye-movement file. One recording takes about a minute with a parallel
pool. Results for different radii are kept side by side, since the radius is
part of the file name.

To process your own recordings, put the csv files in `data/trajectories/`: the
`config.json` of the repository takes every csv file of that folder. To process
only some of them, or files in another folder, name them in `config.json`.

### Step 4 (optional). A video to check a recording by eye

With `"make_video": true` in `config.json`, step 3 also makes a video of every
trial (`results/videos/<name>_r<radius>deg_trial<N>_<condition>.mp4`, about 2
minutes per trial). A video can also be made afterwards from a result file:

```matlab
make_trajectory_video('results/local_statistics_ABF_1_BR_gaze_trajectory_coordinates_r1.5deg.mat')
```

Section 8 explains how to read the video.

### One call with other settings

The arguments of `compute_local_statistics` override `config.json` for one
call, without editing the file:

```matlab
compute_local_statistics('data/trajectories/ABF_1_BR_gaze_trajectory_coordinates.csv')               % this file only
compute_local_statistics('data/trajectories/ABF_1_BR_gaze_trajectory_coordinates.csv', 2.5, false)   % radius 2.5 deg, no video
```

## 6. The eye-movement file

One csv file per recording (one trial), with one row per gaze sample:

| Column | Content |
| --- | --- |
| `Timestamp_ms` | time stamp of the eye tracker [ms] (not used) |
| `Time_sec` | time from the start of the recording [s] |
| `Gaze_X`, `Gaze_Y` | gaze position in stimulus pixels: the frame of the stimulus as displayed, 1080 x 1080 pixels with the origin at its top-left corner, x rightward, y downward; `NaN` for missing samples (blinks) |
| `EventLabel` | event label of the sample (optional; passed on to the result as it is) |

The condition, the observer and the number of the trial are read from the
**file name**, whose parts are separated by underscores: the part that is a
condition (`BC`, `BR`, ..., `PS`), the first part (the observer) and the part
that is a number (the question asked), in any order. For example,
`ABF_1_BR_gaze_trajectory_coordinates.csv` is observer ABF, question 1,
condition BR (statue B, material R). A file whose name holds no condition is
refused.

Three recordings are in `data/trajectories/` as examples.

**Coordinates.** The positions are converted to pixels of the 1024-px stimulus
image by `utils/screen_to_image.m`, using the rectangle that the image occupies
in the coordinates of the file (`advanced.gaze_file.image_rect_px` in
`config.json`, `[0, 0, 1080, 1080]`). For gaze in screen pixels, put the
rectangle of the image on the screen there.

**Time.** The time of every sample is read from the file (`Time_sec`). The
file does not say when each frame appeared, so the 240 frame steps of a trial
are spread evenly over the recording, from its first to its last sample (see
section 9). The eye tracker samples faster than the frames change: the samples
recorded while a frame was on the screen are reduced to their median, which
gives one gaze position per frame step; a step with fewer than half of its
samples (blink, track loss) has no gaze position, and its statistics are NaN.

A second layout is also read: a table of several trials already in image
pixels, with the columns `trial`, `observer`, `condition`, `task`, `time_s`,
`x_px`, `y_px` (described in `utils/load_trajectories.m`).

## 7. Reading the results

### The whole statue

`results/global_statistics.mat` holds one struct, `G`:

```matlab
load results/global_statistics.mat
G.conditions            % {'BC','BR','BS','HC','HR','HS','PC','PR','PS'}
G.frame.names           % 127 names: 122 image statistics + 5 of the silhouette
G.frame.values          % 9 x 61 x 127   [condition, rendered frame, statistic]
G.pair.names            % 20 names of the motion statistics
G.pair.values           % 9 x 60 x 20    [condition, pair of neighbouring frames, statistic]
G.clip.names            % 8 names of the statistics of the whole swing
G.clip.values           % 9 x 8          [condition, statistic]
G.summary.names         % 147 names: the frame and pair statistics
G.summary.mean          % 9 x 147: mean over the 240 frame steps of a trial (also .sd, .min, .max)
G.sequence              % the presentation: frame, angle and time of each of the 240 frame steps
G.catalog               % table: name, family, scope, label and definition of every statistic
G.cfg                   % the configuration used
```

The time course of one statistic over a trial:

```matlab
c = strcmp(G.conditions, 'BR');  k = strcmp(G.frame.names, 'hl_cover_8x');
plot(G.sequence.time, squeeze(G.frame.values(c, G.sequence.frame, k)));
xlabel('Time [s]'); ylabel('hl\_cover\_8x');
```

### Around the gaze position

`results/local_statistics_<name>_r<radius>deg.mat` holds one struct, `Lc`:

```matlab
load results/local_statistics_ABF_1_BR_gaze_trajectory_coordinates_r1.5deg.mat
Lc.trials               % table: trial, observer, condition, task
Lc.radius_deg           % radius of the window [deg]
Lc.names                % 148 names: 6 of the window + 122 image + 20 motion statistics
Lc.values               % trials x 240 x 148   [trial, frame step, statistic]
Lc.time                 % trials x 240 onset of each frame step in the recording [s]
Lc.frame, Lc.angle      % 1 x 240 the frame shown at each step and its rotation angle
Lc.gaze_x, Lc.gaze_y    % trials x 240 gaze position per frame step [image px]
Lc.event                % trials x 240 event label per frame step, as in the gaze file
Lc.summary.mean         % trials x 148: mean over the trial (also .sd, .min, .max, .late_minus_early, .n_valid)
Lc.catalog              % table: name, family, scope, label and definition of every statistic
Lc.source, Lc.cfg       % the trajectory file and the configuration used
```

The time course of one statistic in the gaze window:

```matlab
k = strcmp(Lc.names, 'edge_density');
plot(Lc.time(1, :), Lc.values(1, :, k));
xlabel('Time [s]'); ylabel('edge\_density');
```

The gaze window against the whole statue, for the same statistic and the same
frames:

```matlab
load results/global_statistics.mat
name  = 'lum_mean';
c     = strcmp(G.conditions, Lc.trials.condition(1));
local = Lc.values(1, :, strcmp(Lc.names, name));
whole = squeeze(G.frame.values(c, Lc.frame, strcmp(G.frame.names, name)));
plot(Lc.time(1, :), local, Lc.time(1, :), whole);
legend('gaze window', 'whole statue'); xlabel('Time [s]'); ylabel('lum\_mean');
```

The definition of a statistic, and the means over the trial as a csv table:

```matlab
Lc.catalog(strcmp(Lc.catalog.name, 'hl_sharpness'), :)

S = array2table(Lc.summary.mean, 'VariableNames', Lc.names);
writetable([Lc.trials, S], 'summary_mean.csv');
```

### Notes

* Steps without gaze, or with less than 10% of the window on the statue, are
  NaN and are ignored by the summaries (`Lc.summary.n_valid` counts the steps
  that have a value).
* The first six statistics of `Lc` describe the window itself: how much of it
  lies on the statue (`win_coverage`), whether gaze is on the statue
  (`gaze_on_object`), and where on the statue it is.
* A motion statistic at a frame step describes the change from that frame to
  the next one shown.
* `hue_mean` is an angle; average it with circular statistics.

## 8. The check video

The video shows a trial at half speed, for checking by eye that the gaze
position, the window and the statistics are what they should be.

* **Left, top**: the stimulus as it was shown, with the gaze window (circle)
  and the recent gaze path.
* **Left, bottom**: the gaze window enlarged, the time and the rotation angle
  of the statue. In the enlarged window, the pixels that do not enter the
  statistics are dimmed.
* **Right**: every statistic of the result file as a bar (148 bars in four
  columns, named as in `Lc.names` and colored by family).

How to read a bar:

* The **length of the bar** is the value of the statistic in the gaze window
  at that moment.
* The **axis of the bar** runs from the 5th percentile (left end) to the 95th
  percentile (right end) of the values over the recording. The values
  themselves are in `Lc.values`.
* **Statistics of the same quantity share one axis**, so that their bars can
  be compared with one another. The luminance statistics, for example
  (`lum_mean`, `lum_median`, `lum_sd`, `lum_p01` ... `lum_max`), are all drawn
  on one luminance axis, from zero to the highest 95th percentile among them: a
  bar twice as long is twice the luminance. A shared axis starts at zero when
  its values are all positive; otherwise it runs from the lowest 5th to the
  highest 95th percentile of the group. The table below lists the groups.
* A statistic that is in no group has its own axis. A long bar then means a
  high value relative to the rest of the trial, not a high absolute value.
* The **white tick** is the value of the whole statue in the same frame, on the
  same axis. A bar that ends to the right of its tick means that the region
  looked at has a higher value than the statue as a whole. The ticks are shown
  if `results/global_statistics.mat` exists; the six statistics of the window
  have none.

| Shared axis | Statistics |
| --- | --- |
| luminance | `lum_mean`, `lum_median`, `lum_sd`, `lum_p01` ... `lum_p999`, `lum_max` |
| log10 ratio of luminances | `loglum_sd`, `loglum_range`, `loglum_upper_tail`, `loglum_lower_tail`, `contrast_dynamic_range`, `contrast_robust_range`, `hl_contrast` |
| lightness L\* | `lightness_mean`, `_median`, `_sd`, `_p01`, `_p99` |
| a\*, b\* and chroma | `a_`, `b_` and `chroma_` `mean`, `median`, `sd`, `p01`, `p99` |
| saturation | `saturation_mean`, `_median`, `_sd`, `_p01`, `_p99` |
| skewness | every `*_skew` |
| kurtosis | every `*_kurt` |
| correlation (fixed axis, -1 to 1) | every `corr_*` |
| distance in the u'v' diagram | `uv_dist_mean`, `uv_dist_sd` |
| RGB saturation | `sat_rgb_mean`, `sat_rgb_sd`, `sat_highlight`, `sat_body`, `sat_highlight_drop` |
| opponent chromaticity of the highlights | `hl_rg`, `hl_yb` |
| fraction of the pixels of the region | `lum_dark_frac`, `lum_bright_frac`, `hl_cover_2x` ... `hl_cover_16x`, `hl_frac_half_max`, `hl_coverage` |
| contrast to the mean | `contrast_local`, `contrast_local_blur` |
| Meese-Summers contrast | `contrast_meese_summers`, `contrast_meese_summers_blur` |
| gradient of L\* | `edge_density`, `hl_sharpness` |
| RMS contrast of L\*/100 | `band_rms_1` ... `band_rms_5`, `spec_rms_low`, `spec_rms_mid`, `spec_rms_high` |
| log10 pyramid energy | `pyr_level_1` ... `pyr_level_4` |
| anisotropy of the pyramid | `pyr_anisotropy_fine`, `pyr_anisotropy_coarse` |
| speed | `flow_speed`, `flow_speed_sd`, `flow_hl_speed`, `track_speed` |
| divergence and curl of the flow | `flow_divergence`, `flow_curl` |
| gaze position in the bounding box (fixed axis, 0 to 1) | `gaze_x_rel`, `gaze_y_rel` |

## 9. The experiment: visual angle and presentation

Two entries of `config.json` describe the experiment, and one assumption about
the recordings is built into the code. Change the entries if the experiment
was different, and compute the statistics again.

| | Value in the experiment | Used for |
| --- | --- | --- |
| `image_size_deg` | 27.6: the stimulus image spans 27.6 deg | the size of the gaze window in pixels, and the statistics defined in degrees |
| `start_frame` | 61: a trial starts at the extreme on the left, swings to the right and back | which frame was on the screen at each gaze sample |
| timing of the frames | a recording spans the two cycles of the trial: the 240 frame steps are spread evenly over it (13.5 s, about 56 ms per step) | the same |

The frame shown first and the timing only affect the local statistics.

**The visual angle.** The visual angle that the stimulus image spans is set in
`config.json` (`image_size_deg`) and nowhere else. In the experiment the image
was 39.3 cm high (the full height of the display) and was viewed from 80 cm, so
it spanned 2 x atan(39.3 / (2 x 80)) = 27.6 deg. With the 1024 pixels of the
stimulus image, one degree is 37.1 image pixels, and a window of radius 1.5 deg
is 55.7 pixels in radius. The value
sets the size of the gaze window and enters the statistics that are defined in
degrees: the six whose names end in `_deg` (size and position of the
silhouette, position of gaze) and the two contrast statistics that use a local
mean over 0.5 deg (`contrast_local_blur`, `contrast_meese_summers_blur`). After
changing it, run steps 2 and 3 again.

Pixels and degrees are converted linearly. `px_to_deg` and `deg_to_px` (in
`utils/`) do the conversion with the value of the file, for example to express
the speed of the optical flow in degrees per second:

```matlab
addpath utils
k = strcmp(Lc.names, 'flow_speed');                                   % pixels per frame step
speed = px_to_deg(Lc.values(1, :, k)) ./ median(diff(Lc.time(1, :)));   % degrees per second
```

**The presentation.** The 61 frames sample one sinusoidal swing at equal time
steps: frame 1 is the central view, frames 2-31 run from the centre to the
extreme on the right and frames 32-61 from the centre to the extreme on the
left. A trial starts at the extreme on the left (frame 61), swings to the right
and comes back: one cycle is 61, 60, ..., 32, 1, 2, ..., 31, 30, ..., 2, 1, 32,
..., 60 (120 frame steps), and a trial shows two cycles (240 frame steps).
[`utils/presentation_sequence.m`](utils/presentation_sequence.m) returns the
frame shown at every step. For a trial that starts at the central view, set
`"start_frame": 1` in `config.json` (and `advanced.presentation.start_direction`:
1 for a first movement to the right, -1 to the left).

**The timing of the frames.** A gaze file gives the time of every sample but
not the time at which each frame appeared. A recording is therefore taken to
span exactly the two cycles of the trial: its 240 frame steps are spread evenly
from the first to the last sample (`utils/gaze_per_step.m`). The example
recordings last 13.50 to 13.57 s, so a frame step is about 56 ms. If recordings
include time before or after the motion, they must be cut to the motion first.

## 10. The statistics

There are 161 statistics. [docs/statistics.md](docs/statistics.md) lists every
one with its definition; the same table is returned by `statistic_catalog()`
(in `utils/`) and stored in every result file (`G.catalog`, `Lc.catalog`).

| Family | Scope | N | Content |
| --- | --- | --- | --- |
| `luminance` | frame | 24 | distribution of luminance and log luminance: moments, percentiles, tails |
| `color` | frame | 41 | distribution of CIELAB L\*, a\*, b\*, chroma and saturation; hue; chromaticity |
| `color_luminance` | frame | 5 | correlations between lightness and color across pixels |
| `contrast` | frame | 6 | global contrast estimators (dynamic range, local contrast, Meese-Summers) |
| `highlight` | frame | 19 | coverage, number, size, shape, sharpness and color of the highlights |
| `spatial` | frame | 27 | edges, band-pass contrast, amplitude spectrum, steerable-pyramid energy, orientation |
| `temporal` | pair | 6 | change of the image between two successive frames |
| `flow` | pair | 10 | dense optical flow: speed, affine residual, divergence, curl |
| `tracking` | pair | 4 | optic-flow cues to shininess (Doerschner et al., 2011): tracked fraction, its change, rigidity |
| `geometry` | object | 5 | area, size and position of the silhouette |
| `geometry` | window | 6 | where the gaze window lies on the statue |
| `temporal` | clip | 8 | the whole swing: pixel variation, decorrelation from the central view |

**Scope.** *Frame* statistics (122) come from one frame and *pair* statistics
(20) from two frames that follow each other on the screen; both are pooled over
a region, either the whole statue or a gaze window. *Object* statistics (5)
describe the silhouette and *clip* statistics (8) the whole presented sequence
of a condition; they exist only globally. *Window* statistics (6) describe the
gaze window and exist only locally. The global file therefore holds 155
statistics (127 per frame, 20 per frame pair, 8 per condition) and a local file
148 (6 + 122 + 20).

**Units.** Luminance is linear with 1 = display white; L\*, a\*, b\* are
CIELAB relative to the display white. Lengths are in pixels of the 1024-px
image unless the name ends in `_deg`. Motion is in pixels per frame step of the
presentation; convert with `px_to_deg` and divide by the duration of a frame
step (the spacing of `Lc.time`, about 0.056 s) for degrees per second.

**Highlights** are defined relative to the whole statue in that frame (the
brightest 5% of its pixels; multiples of its median luminance), so that their
coverage is meaningful inside a window.

### Which pixels enter a statistic

The statue is rendered against a black background. Neither the background nor
the contour of the statue against it says anything about the material, so both
are kept out of every statistic:

* The silhouette is the union over the three materials of the lit pixels (the
  geometry is the same, and glossy materials have black pixels inside the
  object). A pixel is lit from one 8-bit step upward: the renderer's pixel
  filter leaves values near 1e-8 for about 2 px around the object, which a
  threshold of zero would count as object. Openings through which the
  background is seen stay background.
* Pixel statistics are pooled over the *interior*: the silhouette eroded by
  7 px (`advanced.contour.border_px`). A mean over a gaze window is therefore the mean
  over the pixels of the window that lie on the statue, not over the whole
  disk. The width of the band was measured on the stimuli: in material C the
  step of the contour is over within 2 px, but in materials R and S the rim of
  the object is black for a further 2 to 3 px, so the step from black to the
  lit surface lies deeper. There the gradient peaks 3 to 4 px inside the
  silhouette, at up to 7 times its interior level, and is back within 20% of it
  from the 8th pixel. One band is used for all materials, so the three
  materials of a statue are measured over exactly the same pixels.
* Blurred quantities (the local mean, the band-pass images) are normalized
  convolutions over the interior, so no background pixel enters a blurred value.
* Spectra and the steerable pyramid are computed on the image multiplied by a
  window that falls smoothly to zero inside the interior; the gaze window adds
  a raised-cosine taper at its rim.
* Optical flow and tracked points leave out a 15-px band at the contour, where
  the flow describes the outline moving over the background.
* A gaze window with less than 10% of its area on the statue gives NaN.

Values cannot diverge at dark pixels either: log luminance is floored at 1e-4
(`advanced.statistics.lum_floor`), the denominators of saturation and of the ratio
statistics are floored, references use percentiles instead of the minimum and
maximum, and a region with too few pixels returns NaN instead of a value.

## 11. Running time, memory and common problems

| Step | Time with a parallel pool of ten workers |
| --- | --- |
| `compute_global_statistics` | about 6 minutes |
| `compute_local_statistics`, one recording | about 1 minute |
| video of one trial | about 2 minutes |
| `demo`, first run with the three example recordings | about 15 minutes |

The scripts use a parallel pool of the default size. With ten workers they need
about 10 GB of memory, since a condition is held in memory while it is
processed; fewer workers need less. Without the Parallel Computing Toolbox the
same loops run serially.

* **A message about `config.json`**: the file could not be read as JSON (a
  missing comma or quote), or the entry named in the message has a value that
  cannot be used (section 4).
* **"No file matches ..."**: an item of `eye_movement_files` in `config.json`
  names no existing file; check the path.
* **"Stimulus files not found"**: put the nine .mat files in
  `data/MAT-images/` (step 1); the message names the files that were not found.
* **"The name of ... does not contain a condition"**: the condition of a
  recording is read from the name of its file (section 6); rename the file so
  that one part between underscores is the condition, for example `BR`.
* **Many NaN in a local result**: gaze was missing (blinks) or beside the
  statue at those steps. `Lc.values(:, :, strcmp(Lc.names, 'win_coverage'))`
  gives the part of the window that was on the statue at each step.
* **No white ticks in the video**: run `compute_global_statistics` first.
* **Out of memory**: start a smaller pool before running the scripts, for
  example `parpool(4)`.

## 12. Files

```
config.json                   every setting: files to process, window, video, visual angle, parameters
demo.m                        runs everything as set in config.json
compute_global_statistics.m   statistics of the whole statue -> results/global_statistics.mat
compute_local_statistics.m    statistics around gaze         -> results/local_statistics_<name>_r<radius>deg.mat
make_trajectory_video.m       video of a trial for checking by eye (optional)
utils/
  load_config.m               reads config.json (holds no settings itself)
  list_eye_movement_files.m   the eye-movement files named in config.json
  px_to_deg.m, deg_to_px.m    pixels <-> degrees of visual angle
  statistic_catalog.m         name, family and definition of every statistic
  load_frames.m               reads the stimulus files as linear RGB
  check_stimuli.m             stops with a message if stimulus files are missing
  load_object_masks.m         silhouette of the statue in every frame
  object_region.m             interior of the statue and the spectral window
  presentation_sequence.m     which frame was on the screen at each moment
  frame_maps.m                per-pixel maps of one frame
  region_statistics.m         image statistics pooled over a region
  pair_maps.m                 change, optical flow and tracked points between two frames
  motion_statistics.m         motion statistics pooled over a region
  clip_statistics.m           statistics of the whole presented sequence
  object_window.m, gaze_window.m       the two kinds of region: whole statue, gaze window
  load_trajectories.m, gaze_per_step.m, screen_to_image.m   eye-movement input
  frame_triplets.m, triplet_maps.m     hand each frame pair its frames (parallel loops)
  summarize_series.m, object_geometry.m, steerable_maps.m
  linear_to_srgb.m, project_colors.m   display (video)
data/MAT-images/              put the nine stimulus files here (not distributed)
data/trajectories/            eye-movement files; three recordings as examples
docs/                         the two figures of this page and the list of statistics
results/                      output (created by the scripts)
```

Every function starts with a description of what it does, its inputs and its
outputs (`help compute_local_statistics`, for example).

## License

MIT; see [LICENSE](LICENSE).
