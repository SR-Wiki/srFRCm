function [parameters,ratios] = background_settings(parameters)
% Resolve the three background modes before any map calculations.
names={'monitorChange','adaptiveBackground'};
for index=1:numel(names)
    value=parameters.(names{index});
    if ~(islogical(value) || isnumeric(value)) || ~isscalar(value) || ...
            ~isreal(value) || ~isfinite(value) || ~ismember(value,[0 1])
        error('srFRC:InvalidBackgroundMode','%s must be a scalar true or false.',names{index});
    end
    parameters.(names{index})=logical(value);
end
if parameters.monitorChange
    parameters.adaptiveBackground=false;
    parameters.backgroundMode='monitor';
    ratios=[0.8 1.0 1.2];
elseif parameters.adaptiveBackground
    parameters.backgroundMode='automatic';
    ratios=1.2;
else
    parameters.backgroundMode='manual';
    ratios=0;
end
end
