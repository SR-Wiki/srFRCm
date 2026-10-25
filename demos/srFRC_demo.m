% Sections 1-2 show the complete input and computation workflow.
% Sections 3-5 demonstrate optional reporting, saving and figure display.
%% 1. Input and analysis settings
clear; clc; close all;
demoDir=fileparts(mfilename('fullpath'));
rootDir=fileparts(demoDir);
addpath(fullfile(rootDir,'src'));
addpath(fullfile(rootDir,'src','Utils')); 

inputFile=fullfile(rootDir,'example_data','Fig2h.tif');
pixelSize=60/1000; % um
singleFrame=true;
threshold='3-sigma'; % Alternative: '1/7 hard threshold'.
adaptiveBackground=false;
monitorChange=true; % True compares 0.8/1.0/1.2 times Otsu and forces adaptiveBackground=false.
backgroundIntensity=30; % Used only when both background switches are false (0-255 scale).
% Optional demo controls; these are not numerical-function parameters.
plotMode='auto'; % Show only currentFrame, with or without batching (plus the next frame in paired mode).
saveResults=true;
% Advanced stack selection.
batchProcessing=false;
currentFrame=1; % One-based; always selects the preview; selects computation too when batchProcessing=false.
parallel=true; % Serial fallback without Parallel Computing Toolbox.
% Use the first frame (single) or first pair (paired) for Fig.2h comparison.
% Match the former combined2_frc_correction window and drift settings.
if singleFrame
    blocksize=64; skip=2; motionCorrection=false;
else
    blocksize=128; skip=4; motionCorrection=true;
end

plotResults=resolve_demo_plot(plotMode,batchProcessing);

%% 2. Numerical computation
% One stack: singleFrame=true analyses each frame independently.
% singleFrame=false analyses adjacent overlapping pairs: (1,2), (2,3), ...
image=read_srfrc_stack(inputFile);
result=srFRC(image,'pixelSize',pixelSize,'singleFrame',singleFrame,'parallel',parallel,...
    'threshold',threshold,'adaptiveBackground',adaptiveBackground,...
    'monitorChange',monitorChange,'backgroundIntensity',backgroundIntensity,...
    'blocksize',blocksize,'skip',skip,'motionCorrection',motionCorrection,...
    'batchProcessing',batchProcessing,'currentFrame',currentFrame);
% Background groups are stored along dimension 4, not the frame dimension 3.
% monitorChange=true produces bg0.8, bg1.0 and bg1.2, even for a single frame.
% result.backgroundGroups lists each group without duplicating its map data.
% Later sections are optional.

%% 3. Optional compact summary display
fprintf('Background mode: %s; groups: %d\n',result.backgroundMode,result.backgroundCount);
disp(struct2table(result.summary));
fprintf('Numerical computation: %.3f s\n',result.computationSeconds);
for g=1:result.backgroundCount
    fprintf('  %s: %.3f s\n',result.backgroundGroups(g).name,...
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
% Separate TIFF/CSV/PNG files retain bg0.8, bg1.0 and bg1.2 in their names.
if plotResults
    plot_srfrc_results(result,directory);
end
if saveResults, fprintf('Results saved to: %s\n',directory); end
