function [s, names] = clip_statistics(frames, masks, seq, cfg)
% CLIP_STATISTICS  Statistics of the whole presented sequence of one condition.
%
%   [s, names] = clip_statistics(frames, masks, seq, cfg)
%
%   frames  H x W x 3 x N linear RGB frames of the condition (load_frames)
%   masks   H x W x N silhouettes (load_object_masks)
%   seq     presentation sequence (presentation_sequence)
%   s       1 x K values in the order of statistic_catalog('clip')
%
%   These statistics describe how the image changes over the swing at a
%   fixed place on the screen: the variation of every pixel across the
%   presented frames, how far the image at the extremes of the swing has
%   decorrelated from the central view, whether the highlights stay in
%   place, and how fast the image changes. They use the pixels that lie on
%   the interior of the statue in every frame, so that the moving contour
%   never enters.

T = statistic_catalog('clip');
names = T.name';
v = struct();
N = size(frames, 4);

%% ---- L* of the pixels that are on the statue in every frame ---------------
inner = true(size(masks, 1), size(masks, 2));
se = strel('disk', cfg.edge.border_px, 0);
for k = 1:N
    inner = inner & imerode(masks(:, :, k), se);
end
Y = squeeze(0.2126 * frames(:, :, 1, :) + 0.7152 * frames(:, :, 2, :) + 0.0722 * frames(:, :, 3, :));
Y = reshape(Y, [], N);
Y = double(Y(inner(:), :));                               % pixels x frames
f = @(t) (t > (6/29)^3) .* nthroot(max(t, 0), 3) + (t <= (6/29)^3) .* (t / (3 * (6/29)^2) + 4/29);
L = 116 * f(Y) - 16;

%% ---- variation of each pixel over one cycle of the presentation -----------
cycle = seq.frame(1:numel(seq.frame) / cfg.presentation.n_cycles);
tsd = std(L(:, cycle), 0, 2);
central = 1;                                               % frame 1 is the central view
bright = L(:, central) >= prctile(L(:, central), 100 * (1 - cfg.stats.hl_fraction));
v.pix_temporal_sd = mean(tsd);
v.pix_temporal_sd_p90 = prctile(tsd, 90);
v.pix_temporal_sd_bright = mean(tsd(bright));
v.pix_temporal_sd_ratio = log10(mean(tsd(bright)) / max(mean(tsd(~bright)), eps));

%% ---- decorrelation and highlight persistence over the swing ---------------
q = cfg.presentation.frames_per_quarter;
[~, k_half] = min(abs(sin(pi / 2 * (1:q) / q) - 0.5));     % step at half the amplitude
half = [1 + k_half, q + 1 + k_half];
extreme = [q + 1, N];
rho = @(a, b) corr(L(:, a), L(:, b));
v.decorr_half    = 1 - mean([rho(central, half(1)), rho(central, half(2))]);
v.decorr_extreme = 1 - mean([rho(central, extreme(1)), rho(central, extreme(2))]);
dice = zeros(1, 2);
for j = 1:2
    hk = L(:, extreme(j)) >= prctile(L(:, extreme(j)), 100 * (1 - cfg.stats.hl_fraction));
    dice(j) = 2 * nnz(bright & hk) / (nnz(bright) + nnz(hk));
end
v.hl_persistence_extreme = mean(dice);

%% ---- temporal spectrum over one cycle --------------------------------------
sub = L(1:4:end, cycle);                                   % every fourth pixel is enough
S = abs(fft(sub - mean(sub, 2), [], 2)) .^ 2;
S = sum(S(:, 2:numel(cycle) / 2 + 1), 1);                  % positive temporal frequencies
v.temporal_hf_share = sum(S(ceil(numel(S) / 2) + 1:end)) / sum(S);

s = zeros(1, numel(names));
for k = 1:numel(names)
    s(k) = v.(names{k});
end
end
