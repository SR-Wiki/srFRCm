function [downsampled] = sampling_xy_skip(im, factor)
[h, w, d] = size(im);
new_h = floor(h / factor);
new_w = floor(w / factor);
if mod(new_w, 2) ~= 0
    new_w = new_w - 1;
end
if mod(new_h, 2) ~= 0
    new_h = new_h - 1;
end
downsampled = zeros(new_h, new_w, d);
for i = 1:new_h
    for j = 1:new_w
    downsampled(i, j, :) = im(floor(1+factor*(i-1)), floor(1+factor*(j-1)), :);
    end
end
end