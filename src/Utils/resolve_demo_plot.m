function enabled = resolve_demo_plot(requested,batchProcessing)
% Resolve demo plotting; the numerical entry points have no plot parameter.
% auto displays only currentFrame, whether batchProcessing is true or false.
% Paired mode displays the calculation for currentFrame and the next frame.
% Plot helpers select this one result; batch computation is unaffected.
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
