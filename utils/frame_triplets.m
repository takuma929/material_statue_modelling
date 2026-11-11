function [rgb3, mask3] = frame_triplets(frames, masks, seq)
% FRAME_TRIPLETS  The frames each pair of neighbouring frames needs, per pair.
%
%   [rgb3, mask3] = frame_triplets(frames, masks, seq)
%
%   frames  H x W x 3 x N frames of a condition (load_frames)
%   masks   H x W x N silhouettes (load_object_masks)
%   seq     presentation sequence (presentation_sequence)
%
%   rgb3{p}   H x W x 3 x 3: the two frames of pair p in the order of
%             increasing rotation angle and the frame one step further
%             (H x W x 3 x 2 for the last pair, which has no further frame)
%   mask3{p}  the silhouettes of those frames
%
%   The motion statistics of a pair need these frames (pair_maps). Putting
%   them in one cell per pair lets a parfor loop over the pairs send each
%   worker only the frames of its own pairs, instead of a copy of the whole
%   condition.

nP = size(seq.pair_frames, 1);
nF = numel(seq.order);
rgb3 = cell(1, nP); mask3 = cell(1, nP);
for p = 1:nP
    idx = seq.order(p:min(p + 2, nF));
    rgb3{p}  = frames(:, :, :, idx);
    mask3{p} = masks(:, :, idx);
end
end
