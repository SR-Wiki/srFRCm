function [map,statistics] = map_statistics(map,originalPixelSizeNm)
% Final output map is modified before any scientific summary is calculated.
map=single(map);
map(map<=0)=0;
if nargin>1
    if ~isscalar(originalPixelSizeNm) || ~isfinite(originalPixelSizeNm) || originalPixelSizeNm<=0
        error('srFRC:InvalidPixelSize','Enter a positive, finite original pixel size in nm.');
    end
    minimum=2.3*double(originalPixelSizeNm);
    floorValue=single(minimum);
    if ~isfinite(floorValue)
        error('srFRC:InvalidPixelSize','The original pixel size is too large for a single-precision resolution map.');
    end
    if double(floorValue)<minimum, floorValue=floorValue+eps(floorValue); end
    foreground=isfinite(map) & map>0;
    map(foreground)=max(map(foreground),floorValue);
end
values=double(map(isfinite(map) & map>0));
statistics=struct('mean_resolution_nm',NaN,'min_resolution_nm',NaN,...
    'max_resolution_nm',NaN,'rFRC_value',NaN);
if isempty(values), return; end
statistics.mean_resolution_nm=mean(values);
statistics.min_resolution_nm=min(values);
statistics.max_resolution_nm=max(values);
statistics.rFRC_value=statistics.mean_resolution_nm/statistics.min_resolution_nm-1;
end
