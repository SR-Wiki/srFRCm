function result = radial_sum(data, radial_step)
% Fast, numerically equivalent radial sum with precomputed round-based bins.
% Preserve MATLAB round(), 1-based accumarray, original output vector.
persistent cachedShape cachedStep cachedBins
shape = size(data);
if isempty(cachedBins) || ~isequal(cachedShape,shape) || ~isequal(cachedStep,radial_step)
    x = (1:shape(2)) - shape(2)/2;
    y = (1:shape(1)) - shape(1)/2;
    [X,Y] = meshgrid(x,y);
    cachedBins = round(abs(X+1i*Y)/radial_step)+1;
    cachedShape = shape;
    cachedStep = radial_step;
end
result = accumarray(cachedBins(:),data(:),[],@sum);
end
