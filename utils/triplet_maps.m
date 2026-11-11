function [Ma, Mb, Mc] = triplet_maps(rgb, masks, cfg)
% TRIPLET_MAPS  Maps of the frames of one pair, as pair_maps expects them.
%
%   [Ma, Mb, Mc] = triplet_maps(rgb, masks, cfg) takes one cell of
%   frame_triplets (the two frames of a pair and, if there is one, the next
%   frame, with their silhouettes) and returns the 'basic' maps of each
%   (frame_maps). Mc is empty for the last pair.

Ma = frame_maps(rgb(:, :, :, 1), masks(:, :, 1), cfg, 'basic');
Mb = frame_maps(rgb(:, :, :, 2), masks(:, :, 2), cfg, 'basic');
Mc = [];
if size(rgb, 4) >= 3
    Mc = frame_maps(rgb(:, :, :, 3), masks(:, :, 3), cfg, 'basic');
end
end
