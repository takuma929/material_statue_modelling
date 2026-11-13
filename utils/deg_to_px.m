function px = deg_to_px(deg, cfg)
% DEG_TO_PX  Convert a length in degrees of visual angle to image pixels.
%
%   px = deg_to_px(deg) converts lengths in degrees of visual angle to
%   pixels of the 1024-px stimulus image, with the visual angle of the
%   image given in config.json (image_size_deg). deg can be an
%   array. For example, deg_to_px(1.5) is the radius of the default gaze
%   window in pixels.
%   px = deg_to_px(deg, cfg) uses the configuration cfg instead of reading
%   the file again.
%
%   See also PX_TO_DEG.

if nargin < 2, cfg = load_config(); end
px = deg * cfg.display.px_per_deg;
end
