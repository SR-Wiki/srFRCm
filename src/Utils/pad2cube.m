function [padded, mask] = pad2cube(im, pad_value)
if nargin < 2
    pad_value = 1;
end
% im = im./max(im(:));
comple = mod(size(im), 2);
mask = ones(size(im));
im = padarray(im, comple, "symmetric", 'post');
mask = padarray(mask, comple, 1, 'post');

max_dim = max(size(im));
pad_shape = floor((max_dim - size(im)) ./ 2);
[h,w,d] = size(im);
Hn = Hanning_3D(h,w,d);
if pad_value == 0
    padded = padarray(im.*Hn, pad_shape, 0);
else
    padded = padarray(im, pad_shape, "symmetric");
    [h,w,d] = size(padded);
    Hn = Hanning_3D(h,w,d);
    padded = padded.*Hn;
end
padded = 255.*padded./max(padded(:));

end