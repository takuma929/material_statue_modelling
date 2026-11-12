function deg = px_to_deg(px, cfg)
% PX_TO_DEG  Convert a length in image pixels to degrees of visual angle.
%
%   deg = px_to_deg(px) converts lengths in pixels of the 1024-px stimulus
%   image to degrees of visual angle, with the visual angle of the image
%   given in display_config.json (image_size_deg). px can be an array.
%   deg = px_to_deg(px, cfg) uses the configuration cfg instead of reading
%   the file again.
%
%   Most statistics that are lengths or speeds are stored in pixels (see
%   statistic_catalog); this function is for reporting them in degrees. For
%   example, with a result of compute_local_statistics, the speed of the
%   optical flow in degrees per second:
%
%     k = strcmp(Lc.names, 'flow_speed');                        % px per frame step
%     speed = px_to_deg(Lc.values(1, :, k)) ./ median(diff(Lc.time(1, :)));
%
%   The conversion is linear (degrees = pixels x degrees per pixel). For an
%   image 27.6 deg wide, a degree at the centre of the image is 2% fewer
%   pixels than this average over the image (36.4 instead of 37.1).
%
%   See also DEG_TO_PX.

if nargin < 2, cfg = analysis_config(); end
deg = px / cfg.display.px_per_deg;
end
