function enabled = resolve_z_sampling(value)
% Manual switch only. Legacy [] is accepted as OFF, without a spacing rule.
if isempty(value)
    enabled=false;
elseif isscalar(value) && (islogical(value) || (isnumeric(value) && isfinite(value) && ismember(value,[0 1])))
    enabled=logical(value);
else
    error('sFSC:InvalidZSampling','zSampling must be true or false (default). Legacy [] means false.');
end
end
