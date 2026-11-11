function [x, y] = screen_to_image(xs, ys, cfg)
% SCREEN_TO_IMAGE  Convert gaze coordinates of a recording to stimulus-image pixels.
%
%   [x, y] = screen_to_image(xs, ys, cfg) converts gaze positions from the
%   coordinates of the gaze file to pixels of the 1024-px stimulus image,
%   the coordinates used by every function of this repository ((1, 1) =
%   centre of the top-left pixel of the image; x rightward, y downward).
%
%   cfg.display.image_rect_px = [left top width height] is the rectangle
%   the image occupies in the coordinates of the gaze file. The gaze files
%   of this experiment are in "stimulus pixels", the frame of the displayed
%   stimulus (1080 x 1080, origin at its top-left corner), so the rectangle
%   is [0 0 1080 1080]. For gaze in screen pixels (EyeLink convention:
%   origin at the top-left corner of the screen), give the rectangle of the
%   image on the screen instead.

rect  = cfg.display.image_rect_px;
scale = cfg.stimulus.image_size_px ./ rect(3:4);       % image pixels per unit of the gaze file
x = (xs - rect(1)) * scale(1) + 0.5;
y = (ys - rect(2)) * scale(2) + 0.5;
end
