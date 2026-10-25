function [resolution,curve,required,used,attempted] = resolve_frc_curve(curve,singleFrame,threshold,allowExtrapolation)
% Internal measured-only control; user APIs automatically extrapolate 1/7.
if nargin<4, allowExtrapolation=true; end
% Every frame must have the same fields for MATLAB struct-array batching,
% even when only a subset of frames requires automatic extrapolation.
optional={'extrapolatedFRC','newFrequence','extrapolationFitInfo','extraFixedThreshold','extrapolatedIndex'};
for i=1:numel(optional)
    if ~isfield(curve,optional{i}), curve.(optional{i})=[]; end
end
curve.extrapolationFailure='';
if singleFrame, resolution=curve.resolutionCorrected;
else, resolution=curve.resolution; end
required=~isfinite(resolution) || resolution<=0;
used=false; attempted=false;
curve.extrapolationRequired=required; curve.extrapolationUsed=false;
curve.extrapolationAttempted=false;
if ~required || ~allowExtrapolation || ~strcmp(threshold,'1/7')
    curve.reportedResolution=resolution; return;
end
attempted=true; curve.extrapolationAttempted=true;
if isfield(curve,'smoothedFRCCorrected')
    if singleFrame, data=curve.smoothedFRCCorrected; else, data=curve.smoothedFRC; end
else
    if singleFrame, data=curve.smoothedFSCCorrected; else, data=curve.smoothedFSC; end
end
try
    [curve.extrapolatedFRC,curve.newFrequence,curve.extrapolationFitInfo]=...
        extrapolateFRCCurve_v2(data,2*numel(data),curve.frequence);
    curve.extraFixedThreshold=ones(size(curve.extrapolatedFRC))/7;
    [curve.extrapolatedIndex,resolution]=get_resolution(curve.newFrequence,curve.extrapolatedFRC,curve.extraFixedThreshold);
    used=isfinite(resolution) && resolution>0;
    curve.extrapolationUsed=used;
catch ME
    resolution=NaN; curve.extrapolationFailure=ME.message;
end
curve.reportedResolution=resolution;
end
