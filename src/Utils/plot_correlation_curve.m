function fig = plot_correlation_curve(curve,singleFrame,threshold,titleText)
% Display an already computed curve; no numerical analysis is performed here.
fig=figure('Name',titleText,'NumberTitle','off');
if curve.extrapolationUsed
    frequency=curve.newFrequence; data=curve.extrapolatedFRC; cutoff=curve.extraFixedThreshold;
else
    frequency=curve.frequence;
    if singleFrame, data=curve.smoothedFRCCorrected; else, data=curve.smoothedFRC; end
    if isstring(threshold), threshold=char(threshold); end
if any(strcmpi(strtrim(threshold),{'1/7','1/7 hard threshold','fixed_threshold'}))
    cutoff=curve.fixedThreshold;
elseif strcmpi(strtrim(threshold),'3-sigma')
    cutoff=curve.threeSigma;
else
    error('sFRC:InvalidThreshold','Use 1/7 hard threshold or 3-sigma.');
end
end
plot(frequency,data,'Color',[230 115 115]/255); hold on; plot(frequency,cutoff,'k');
xlabel('Spatial frequency (1/um)'); ylabel('Correlation'); title(titleText);
text(.5,.5,sprintf('Resolution: %.2f nm',curve.reportedResolution),'Units','normalized');
end
