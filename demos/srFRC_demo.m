% Sections 1-2 show the complete input and computation workflow.
% Sections 3-5 demonstrate optional reporting, saving and figure display.
%% 1. Input and analysis settings
clear; clc; close all;
demoDir=fileparts(mfilename('fullpath'));
rootDir=fileparts(demoDir);
addpath(fullfile(rootDir,'src'),'-begin');
addpath(fullfile(rootDir,'src','fSNR'),'-begin');
addpath(fullfile(rootDir,'src','Utils'),'-begin');
assert_demo_helper_paths(rootDir,{'plot_srfrc_results','current_result_index','sjet','save_srfrc_maps','save_srfrc_summary'});

inputFile=fullfile(rootDir,'example_data','Fig2h.tif');
pixelSize=60/1000; % um
singleFrame=true;
threshold='3-sigma'; % Alternative: '1/7 hard threshold'.
adaptiveBackground=false;
monitorChange=true; % True compares 0.8/1.0/1.2 times Otsu and forces adaptiveBackground=false.
backgroundIntensity=30; % Used only when both background switches are false (0-255 scale).
% The demo displays one preview (the first frame/pair by default); saving is optional.
saveResults=true;
% Batch computes all frames/pairs when enabled; the preview always shows one result.
% All previews show the first computed frame/pair; batch mode computes all.
% Advanced stack selection.
batchProcessing=false;
parallel=true; % Serial fallback without Parallel Computing Toolbox.
blocksize=64; % size of rolling block
skip=2; % skip neighboring calculation for speedup
motionCorrection=false; % only for double-frame calculation


%% 2. Numerical computation
% One stack: singleFrame=true analyses each frame independently.
% singleFrame=false analyses adjacent overlapping pairs: (1,2), (2,3), ...
image=read_srfrc_stack(inputFile);
if parallel && isempty(ver('parallel'))
    fprintf('Parallel Computing Toolbox is unavailable; using serial srFRC.\n');
    parallel=false;
end
result=srFRC(image,'pixelSize',pixelSize,'singleFrame',singleFrame,'parallel',parallel,...
    'threshold',threshold,'adaptiveBackground',adaptiveBackground,...
    'monitorChange',monitorChange,'backgroundIntensity',backgroundIntensity,...
    'blocksize',blocksize,'skip',skip,'motionCorrection',motionCorrection,...
    'batchProcessing',batchProcessing);
% Background groups are stored along dimension 4, not the frame dimension 3.
% monitorChange=true returns three groups, labelled by absolute backgroundThreshold in the summary.
% result.backgroundGroups lists each group without duplicating its map data.
% Later sections are optional.

%% 3. Optional compact summary display
fprintf('Background mode: %s; groups: %d\n',result.backgroundMode,result.backgroundCount);
% Keep group IDs in result.summary for file exports, not the user-facing table.
summaryTable=struct2table(result.summary);
if ismember('background_setting',summaryTable.Properties.VariableNames)
    summaryTable.background_setting=[];
end
preferred={'mean_resolution_nm','min_resolution_nm','max_resolution_nm','rFRC_value','background_threshold'};
preferred=preferred(ismember(preferred,summaryTable.Properties.VariableNames));
if ~isempty(preferred),summaryTable=movevars(summaryTable,preferred,'Before',1);end
disp(summaryTable);
fprintf('Numerical computation: %.3f s\n',result.computationSeconds);
for g=1:result.backgroundCount
    fprintf('  Background group %d: %.3f s\n',g,...
        result.backgroundComputationSeconds(g));
end

%% 4. Optional numerical-result export
% This demo section owns results/ creation and file writing.
directory=''; % Empty means display without saving previews.
if saveResults
    directory=fullfile(pwd,'results');
    if ~isfolder(directory), mkdir(directory); end
    save_srfrc_summary(directory,result);
    save_srfrc_maps(directory,result);
end
%% 5. Optional map display and preview export
% All current-frame background groups appear side by side using sjet.
% Exported file names retain internal group IDs, but figures show absolute thresholds.
plot_srfrc_results(result,directory);
if saveResults, fprintf('Results saved to: %s\n',directory); end
