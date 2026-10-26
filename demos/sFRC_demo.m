% Sections 1-2 show the complete input and computation workflow.
% Sections 3-5 demonstrate optional reporting, saving and figure display.
%% 1. Input and analysis settings
clear; clc; close all;
demoDir=fileparts(mfilename('fullpath'));
rootDir=fileparts(demoDir);
% Shared numerical helpers live in src/fSNR; plotting and I/O helpers live in src/Utils.
addpath(fullfile(rootDir,'src'));
addpath(fullfile(rootDir,'src','Utils'));
addpath(fullfile(rootDir,'src','Utils'),'-end');

inputFile=fullfile(rootDir,'example_data','Fig3a_Raw.tif');
% Alternative input: fullfile(rootDir,'example_data','Fig2b_SD-SIM.tif');

pixelSize=60/1000; % um
singleFrame=false;
threshold='1/7 hard threshold'; 
% Optional demo controls; these are not numerical-function parameters.
plotMode='auto'; % Show only currentFrame, with or without batching (plus the next frame in paired mode).
saveResults=true;
% Advanced stack selection.
batchProcessing=true;
currentFrame=1; % One-based; always selects the preview; selects computation too when batchProcessing=false.

plotResults=resolve_demo_plot(plotMode,batchProcessing);

%% 2. Numerical computation
% One stack: singleFrame=true analyses each frame independently.
% singleFrame=false analyses adjacent overlapping pairs: (1,2), (2,3), ...
image=imreadstack(inputFile);
FRC=sFRC(image,'pixelSize',pixelSize,'singleFrame',singleFrame,...
    'threshold',threshold,...
    'batchProcessing',batchProcessing,'currentFrame',currentFrame);
% FRC now contains the numerical results; the remaining sections are optional.

%% 3. Optional compact summary display
summary=[FRC.summary];
disp(struct2table(summary));

%% 4. Optional numerical-result export
% This demo section owns results/ creation and file writing.
directory=''; % Empty means display without saving previews.
if saveResults
    directory=fullfile(pwd,'results');
    if ~isfolder(directory), mkdir(directory); end
    save_demo_summary(directory,'sFRC',FRC,summary,FRC(1).parameters);
end
%% 5. Optional curve display and preview export
% Plotting/preview helpers live in src/Utils/ and consume the completed results.
if plotResults
    plot_sfrc_results(FRC,singleFrame,directory);
end
if saveResults, fprintf('Results saved to: %s\n',directory); end
