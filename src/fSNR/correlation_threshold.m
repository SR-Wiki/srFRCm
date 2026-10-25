function threshold = correlation_threshold(value,owner)
% Resolve public criteria to internal values. Use one shared implementation.
if nargin<2, owner='srFRC'; end
if isstring(value) && isscalar(value), value=char(value); end
if ischar(value) && isrow(value)
    value=lower(strtrim(value));
    if ismember(value,{'1/7 hard threshold','1/7','fixed_threshold'})
        threshold='1/7'; return;
    elseif strcmp(value,'3-sigma')
        threshold='3-sigma'; return;
    end
end
error([owner ':InvalidThreshold'],'Choose threshold ''1/7 hard threshold'' or ''3-sigma''.');
end
