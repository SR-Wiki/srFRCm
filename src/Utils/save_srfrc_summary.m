function save_srfrc_summary(directory,result)
% Export complete srFRC summary and numerical results, without root utils.
% This is the srFRC-only counterpart of the repository-wide save_demo_summary.
if nargin<1 || isempty(directory), return; end
if ~isfolder(directory), mkdir(directory); end
summary=result.summary;
parameters=result.parameters;
writetable(struct2table(summary),fullfile(directory,'srFRC_results.csv'));
save(fullfile(directory,'srFRC_results.mat'),'result','summary','parameters','-v7.3');
end
