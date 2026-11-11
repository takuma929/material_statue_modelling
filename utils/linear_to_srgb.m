function img = linear_to_srgb(lin, gain)
% LINEAR_TO_SRGB  Encode linear RGB (1 = display white) for display.
%
%   img = linear_to_srgb(lin) applies the sRGB transfer function and clips
%   to [0, 1]. img = linear_to_srgb(lin, gain) first multiplies the linear
%   values by gain (to brighten a dark image for a figure; say so in the
%   caption when a gain other than 1 is used).

if nargin < 2, gain = 1; end
lin = min(max(double(lin) * gain, 0), 1);
img = 12.92 * lin;
hi = lin > 0.0031308;
img(hi) = 1.055 * lin(hi) .^ (1 / 2.4) - 0.055;
end
