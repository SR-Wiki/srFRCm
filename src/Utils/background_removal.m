function result = background_removal(im, iter, ratio, level)
if nargin < 2
    iter = 5;
end
if nargin < 3
    ratio = 1;
end
if nargin < 4
    level = 7;
end
backgrounds = background_estimation(im.*ratio, 1, level, 'db6', iter);
result = im - backgrounds;
result(result<0) = 0;
end