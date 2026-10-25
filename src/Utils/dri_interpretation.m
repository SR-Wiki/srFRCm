function [state,guidance,advice] = dri_interpretation(error)
guidance='E_DRI (relative fit error): <10% reliable; 10-20% use with caution; >20% unacceptable.';
if ~isfinite(error), state='unavailable';
elseif error<0.10, state='reliable';
elseif error>0.20, state='unacceptable';
else, state='use with caution'; end
advice='';
if isfinite(error) && error>=0.10
    advice='Consider adjusting the DRI fitting angle range, then repeat the analysis. Recommended DRI fitting angles: lowAngle > 10 degrees and highAngle < 80 degrees.';
end
end
