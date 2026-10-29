function index = current_result_index(count,parameters)
%CURRENT_RESULT_INDEX Preview one completed numerical result.
%   index = CURRENT_RESULT_INDEX(count,parameters) remains compatible with
%   old plotting helpers. In batch mode the first computed frame/pair is
%   displayed; in non-batch mode the numerical output contains only the
%   requested frame/pair and its result index is likewise 1.
%
%   parameters.currentFrame is optional here because older and newer
%   archives differ in whether batch results retain that metadata field.
if nargin<2 || isempty(parameters), parameters=struct(); end %#ok<NASGU>
if ~isnumeric(count) || ~isscalar(count) || ~isfinite(count) || count<0 || count~=fix(count)
    error('srFRC:InvalidResultCount','Number of computed results must be a nonnegative integer.');
end
if count>0
    index=1;
else
    index=[];
end
end
