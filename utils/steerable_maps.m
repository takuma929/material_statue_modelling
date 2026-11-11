function E = steerable_maps(img, n_levels, n_orient)
% STEERABLE_MAPS  Local energy of a steerable pyramid, per level and orientation.
%
%   E = steerable_maps(img, n_levels, n_orient) filters img with the
%   band-pass oriented filters of a steerable pyramid (Simoncelli & Freeman,
%   1995) built in the frequency domain, without subsampling. E is
%   H x W x n_levels x n_orient: the magnitude of the complex (quadrature)
%   response at every pixel. Level 1 is the finest octave: level l passes
%   spatial frequencies around 1 / 2^(l + 1) cycles per pixel (1/4, 1/8,
%   1/16, 1/32 c/px for four levels). Orientation k is the direction of
%   luminance modulation, (k - 1) * 180 / n_orient degrees from horizontal
%   (k = 1: vertical stripes and edges).

if nargin < 2 || isempty(n_levels), n_levels = 4; end
if nargin < 3 || isempty(n_orient), n_orient = 4; end
[h, w] = size(img);
[fx, fy] = meshgrid(((0:w - 1) - floor(w / 2)) / w * 2 * pi, ((0:h - 1) - floor(h / 2)) / h * 2 * pi);
r = hypot(fx, fy);                      % radial frequency [rad per pixel]
theta = atan2(fy, fx);
F = fftshift(fft2(img));
E = zeros(h, w, n_levels, n_orient, 'single');
for l = 1:n_levels
    radial = highpass(2^(l - 1) * r) .* lowpass(2^(l - 2) * r);
    for k = 1:n_orient
        d = angle(exp(1i * (theta - (k - 1) * pi / n_orient)));    % wrapped angular distance
        ang = (abs(d) < pi / 2) .* cos(d) .^ (n_orient - 1);        % one-sided: the response is complex
        E(:, :, l, k) = abs(ifft2(ifftshift(F .* radial .* ang)));
    end
end
end

function L = lowpass(r)
% 1 below pi/4, raised-cosine fall (on a log-frequency axis) to 0 at pi/2
L = ones(size(r), 'like', r);
t = r > pi / 4 & r < pi / 2;
L(t) = cos(pi / 2 * log2(4 * r(t) / pi));
L(r >= pi / 2) = 0;
end

function H = highpass(r)
H = sqrt(max(1 - lowpass(r) .^ 2, 0));
end
