function [downsampled] = sampling_3d_skip(im, factor)
[h, w, d] = size(im);
new_depth = floor(d / factor);
downsampled = zeros(h, w, new_depth);
for i = 1:new_depth
    downsampled(:, :, i) = im(:, :, floor(1+factor*(i-1)));
end
end