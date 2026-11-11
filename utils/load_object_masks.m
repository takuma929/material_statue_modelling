function masks = load_object_masks(cfg, statue)
% LOAD_OBJECT_MASKS  Silhouette of a statue in each of its rendered frames.
%
%   masks = load_object_masks(cfg, statue) returns a logical H x W x N array
%   (N = 61 frames) that is true on the pixels of the statue. 'statue' is a
%   statue letter ('B') or a condition name ('BC'); the mask is the same for
%   the three materials of a statue.
%
%   The mask is the union over the three materials of the lit pixels (any
%   sRGB-encoded channel at or above cfg.mask.threshold, one 8-bit step;
%   the background is exactly black, but the renderer's pixel filter leaves
%   values near 1e-8 around the object, which a threshold of zero would
%   count): the geometry is identical across materials, and a glossy
%   material has black pixels inside the object that another material shows
%   lit. Pinholes are
%   closed and small isolated specks removed. Openings through which the
%   black background is seen (between an arm and the body) are not filled.
%
%   The masks are computed once per statue and stored in
%   results/cache/masks_<statue>.mat together with the settings they were
%   computed from (stimulus format and folder, mask parameters). They are
%   rebuilt automatically when those settings change; after replacing the
%   stimulus files in place, delete the cache folder (or call
%   compute_global_statistics(true)).

statue = statue(1);
file = fullfile(cfg.paths.cache, sprintf('masks_%s.mat', statue));
source = struct('format', cfg.stimulus.format, 'dir', cfg.stimulus.dir, 'mask', cfg.mask);
if exist(file, 'file')
    L = load(file);
    if isfield(L, 'source') && isequal(L.source, source)
        masks = L.masks;
        return
    end
end

thr = cfg.mask.threshold / 12.92;                  % the threshold in linear RGB (below the knee of sRGB)
masks = [];
for m = 1:numel(cfg.materials)
    frames = load_frames(cfg, [statue cfg.materials{m}]);
    lit = squeeze(max(frames, [], 3)) >= thr;          % H x W x N
    if isempty(masks), masks = lit; else, masks = masks | lit; end
end
se = strel('disk', cfg.mask.close_px, 0);
for k = 1:size(masks, 3)
    m = imclose(masks(:, :, k), se);
    masks(:, :, k) = bwareaopen(m, cfg.mask.min_area);
end

if ~exist(cfg.paths.cache, 'dir'), mkdir(cfg.paths.cache); end
save(file, 'masks', 'source');
end
