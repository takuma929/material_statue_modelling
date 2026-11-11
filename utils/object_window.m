function reg = object_window(M, cfg)
% OBJECT_WINDOW  The region "whole object" for region_statistics.
%
%   reg = object_window(M, cfg) returns the region that pools every pixel
%   of the interior of the statue in the frame described by M (frame_maps):
%   the bounding box of the silhouette, the interior mask inside it, no
%   additional taper, and the Fourier size of the whole image.

bb = M.geom.bbox;                       % [top bottom left right]
reg.rows  = bb(1):bb(2);
reg.cols  = bb(3):bb(4);
reg.mask  = M.inner(reg.rows, reg.cols);
reg.taper = ones(numel(reg.rows), numel(reg.cols));
reg.nfft  = cfg.stats.nfft;
end
