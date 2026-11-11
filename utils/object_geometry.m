function [s, names] = object_geometry(M, cfg)
% OBJECT_GEOMETRY  Size and position of the statue's silhouette in one frame.
%
%   [s, names] = object_geometry(M, cfg) returns, in the order of
%   statistic_catalog('object'), the fraction of the image covered by the
%   statue, the width and height of its bounding box and the position of
%   its centroid relative to the image centre [deg]. These are not material
%   statistics; they describe how the silhouette changes as the statue
%   swings, and serve as covariates.

T = statistic_catalog('object');
names = T.name';
[H, W] = size(M.mask);
ppd = cfg.display.px_per_deg;
bb = M.geom.bbox;
v.obj_area_frac      = M.geom.area / (H * W);
v.obj_width_deg      = (bb(4) - bb(3) + 1) / ppd;
v.obj_height_deg     = (bb(2) - bb(1) + 1) / ppd;
v.obj_centroid_x_deg = (M.geom.centroid(1) - (W + 1) / 2) / ppd;
v.obj_centroid_y_deg = (M.geom.centroid(2) - (H + 1) / 2) / ppd;
s = zeros(1, numel(names));
for k = 1:numel(names)
    s(k) = v.(names{k});
end
end
