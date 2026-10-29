function enabled = resolve_demo_plot(requested,batchProcessing)
% Resolve demo plotting; the numerical entry points have no plot parameter.
% In batch mode, auto previews the first computed frame/pair only.
% In non-batch mode, the numerical output contains only the frame/pair
% selected by currentFrame, so the preview likewise shows its sole result.
% Plot helpers select that one result; batch computation is unaffected.
if nargin<2, batchProcessing=false; end
if isstring(requested) && isscalar(requested), requested=char(requested); end
if ischar(requested) && isrow(requested)
    value=lower(strtrim(requested));
    if ~ismember(value,{'auto','true','false'})
        error('sFRC:InvalidPlot','Choose plotMode ''auto'', true, or false in the demo.');
    end
    requested=~strcmp(value,'false');
elseif ~islogical(requested) || ~isscalar(requested)
    error('sFRC:InvalidPlot','Choose plotMode ''auto'', true, or false in the demo.');
end
enabled=requested;
end
