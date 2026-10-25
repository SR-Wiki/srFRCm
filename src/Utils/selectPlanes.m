function [planes] = selectPlanes(im, numSlices)
[~, ~, d] = size(im);
meanValues = zeros(1, d);
for i = 1:d
    slice = im(:, :, i);
    meanValues(i) = mean(slice(:));
end
[~, sortedIndices] = sort(meanValues, 'descend');
planes = sortedIndices(1:numSlices);
end