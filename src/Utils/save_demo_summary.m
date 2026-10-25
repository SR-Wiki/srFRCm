function save_demo_summary(directory,stem,result,summary,parameters)
% Export completed demo results: compact CSV plus MAT curves/maps and metadata.
if isempty(directory), return; end
writetable(struct2table(summary),fullfile(directory,[stem '_results.csv']));
save(fullfile(directory,[stem '_results.mat']),'result','summary','parameters','-v7.3');
if isfield(summary,'E_DRI_percent')
    [~,guidance]=dri_interpretation(NaN);
    file=fopen(fullfile(directory,[stem '_E-DRI-guidance.txt']),'w','n','UTF-8');
    if file<0, error('sFSC:SaveGuidanceFailed','Cannot save E_DRI guidance.'); end
    cleanup=onCleanup(@()fclose(file));
    fprintf(file,'%s\n',guidance);
    fprintf(file,'%s\n','Recommended DRI fitting angles: lowAngle > 10 degrees and highAngle < 80 degrees.');
    if isfield(result,'axialResolutionNote') && ~isempty(result.axialResolutionNote)
        fprintf(file,'%s\n',result.axialResolutionNote);
    end
    for i=1:numel(summary)
        [state,~,advice]=dri_interpretation(summary(i).E_DRI_percent/100);
        fprintf(file,'E_DRI=%.2f%% (%s)\n',summary(i).E_DRI_percent,state);
        if ~isempty(advice), fprintf(file,'%s\n',advice); end
    end
end
end
