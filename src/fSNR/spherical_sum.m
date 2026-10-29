function result = spherical_sum(data, radial_step)
% Fast FSC shell sum with cached geometry and unchanged MATLAB rounding.
persistent cachedShape cachedStep cachedBins
shape = [size(data,1), size(data,2), size(data,3)];
useCache = prod(shape) <= 2000000;
if ~useCache || isempty(cachedBins) || ~isequal(cachedShape,shape) || ~isequal(cachedStep,radial_step)
    x=(1:shape(2))-shape(2)/2;
    y=(1:shape(1))-shape(1)/2;
    z=(1:shape(3))-shape(3)/2;
    [X,Y,Z]=meshgrid(x,y,z);
    bins=round(sqrt(X.^2+Y.^2+Z.^2)/radial_step)+1;
    if useCache
        cachedShape=shape;
        cachedStep=radial_step;
        cachedBins=bins;
    end
else
    bins=cachedBins;
end
result=accumarray(bins(:),data(:),[],@sum);
end
