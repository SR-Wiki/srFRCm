function output = restore_map_size(input,targetSize)
% Restore a quantitative map with separable not-a-knot cubic splines.
% interp1(...,'spline') is applied along X, then Y. Output index j samples
% source coordinate j/2 (zero-based), clamped to the final source sample.
% Original foreground support is repeated without interpolation. Non-positive
% candidates become zero; positive candidates are bounded by the source range.
% The original-pixel-size lower bound and statistics are applied by the caller.
input=double(input);
sourceSize=[size(input,1) size(input,2)];
targetSize=double(targetSize(:).');
if ~ismatrix(input) || isempty(input) || numel(targetSize)~=2 || ...
        any(~isfinite(targetSize)) || any(targetSize~=floor(targetSize)) || any(targetSize<1)
    error('srFRC:InvalidMapSize','Provide a nonempty 2D map and two positive integer target dimensions.');
end
valid=isfinite(input) & input>0;
input(~valid)=0;
if isequal(sourceSize,targetSize), output=single(input); return; end
if ~isequal(sourceSize,floor(targetSize/2))
    error('srFRC:InvalidMapSize','Restoration expects a half-size map or an unchanged paired map.');
end
y=min((0:targetSize(1)-1)'/2,sourceSize(1)-1);
x=min((0:targetSize(2)-1)'/2,sourceSize(2)-1);
support=valid(floor(y)+1,floor(x)+1);
if ~any(valid(:)), output=zeros(targetSize,'single'); return; end
if sourceSize(2)>1
    temporary=interp1(0:sourceSize(2)-1,input.',x,'spline').';
else
    temporary=repmat(input,1,targetSize(2));
end
if sourceSize(1)>1
    output=interp1(0:sourceSize(1)-1,temporary,y,'spline');
else
    output=repmat(temporary,targetSize(1),1);
end
positive=support & isfinite(output) & output>0;
values=input(valid);
output(positive)=min(max(output(positive),min(values)),max(values));
output(~positive)=0;
output=single(output);
end
