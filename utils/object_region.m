function [inner, win, plateau] = object_region(mask, border, taper)
% OBJECT_REGION  Interior of the object and a window that excludes its contour.
%
%   [inner, win, plateau] = object_region(mask, border, taper)
%
%   The statue is rendered against black, so its silhouette is a strong
%   luminance step that says nothing about the material. Three regions keep
%   that step out of the statistics:
%
%   inner    the mask eroded by 'border' pixels (cfg.edge.border_px; default
%            2). Pixel statistics are taken here: the pixels near the
%            boundary, which antialiasing mixes with the background and
%            where the surface emerges from a black rim, are left out, and
%            a central-difference gradient at any pixel of 'inner' uses
%            object pixels only.
%   win      a window equal to 1 well inside the object that falls smoothly
%            to 0 over about 'taper' pixels (default 8) and is 0 from the
%            edge of 'inner' outward. Spectra and the steerable pyramid are
%            computed on the image multiplied by 'win', so that the contour
%            adds no energy.
%   plateau  the pixels where win > 0.99, over which filter responses are
%            averaged.

if nargin < 2 || isempty(border), border = 2; end
if nargin < 3 || isempty(taper), taper = 8; end
inner = imerode(mask, strel('disk', border, 0));
core  = imerode(mask, strel('disk', border + taper, 0));
win   = imgaussfilt(single(core), taper / 2);
win(~inner) = 0;
plateau = win > 0.99;
end
