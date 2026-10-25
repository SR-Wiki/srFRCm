function [stack] = diagonal_resample(img)
img(img < 0) = 0;
rawtest_1 = img(1:2:end-1, 1:2:end-1,:) + img(2:2:end, 2:2:end,:);
rawtest_1 = rawtest_1 / 2;
rawtest_2 = img(1:2:end-1, 2:2:end,:) + img(2:2:end, 1:2:end-1,:);
rawtest_2 = rawtest_2 / 2;
% 2D data
if length(size(img)) == 2
    stack(:, :, 1) = rawtest_1;
    stack(:, :, 2) = rawtest_2;
% 3D data
else
    stack(:, :, :, 1) = rawtest_1;
    stack(:, :, :, 2) = rawtest_2;
end
end