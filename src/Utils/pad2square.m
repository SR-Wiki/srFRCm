function [padded, mask] = pad2square(im, pad_value)
if nargin < 2
    pad_value = 1;
end
% im = im./max(im(:));
comple = mod(size(im), 2);
mask = ones(size(im));
if pad_value == 0
    im = padarray(im, comple, 0, 'post');
else
    im = padarray(im, comple, "symmetric", 'post');
end
mask = padarray(mask, comple, 1, 'post');

max_dim = max(size(im));
pad_shape = floor((max_dim - size(im)) ./ 2);
[h,w] = size(im);
Hm = Hanning(h,w);
if pad_value == 0
    padded = padarray(im.*Hm, pad_shape, 0);
else
    padded = padarray(im, pad_shape, "symmetric");
    [h,w] = size(padded);
    Hm = Hanning(h,w);
    padded = padded.*Hm;
end
padded = 255.*padded./max(padded(:));

end