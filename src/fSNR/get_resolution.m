function [idx, resolution] = get_resolution(frequencies, FRC, threshold)
idx = findIntercept(FRC, threshold);
if idx < 0
    resolution = NaN;
else
    frequency = frequencies(idx);
    resolution = 1000 / frequency;
end
end