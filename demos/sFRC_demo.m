% Sections 1-2 show the complete input and computation workflow.
% Sections 3-5 demonstrate optional reporting, saving and figure display.
%% 1. Input and analysis settings
clear; clc; close all;
demoDir=fileparts(mfilename('fullpath'));
rootDir=fileparts(demoDir);
% Shared numerical helpers live in src/fSNR; plotting and I/O helpers live in src/Utils.
addpath(fullfile(rootDir,'src'),'-begin');
addpath(fullfile(rootDir,'src','fSNR'),'-begin');
addpath(fullfile(rootDir,'src','Utils'),'-begin');
assert_demo_helper_paths(rootDir,{'plot_sfrc_results','current_result_index','plot_correlation_curve','save_demo_summary'});

inputFile=fullfile(rootDir,'example_data','Fig3a_Raw.tif');

pixelSize=60/1000; % um
singleFrame=false;
threshold='1/7 hard threshold'; 
% The demo displays one preview (the first frame/pair by default); saving is optional.
saveResults=true;
% Batch computes all frames/pairs when enabled; the preview always shows one result.
% All previews show the first computed frame/pair; batch mode computes all.
% Advanced stack selection.
batchProcessing=true;


%% 2. Numerical computation
% One stack: singleFrame=true analyses each frame independently.
% singleFrame=false analyses adjacent overlapping pairs: (1,2), (2,3), ...
image=imreadstack(inputFile);
if ~singleFrame && size(image,3)<2
    error('srFRC:DemoNeedsPair', ...
        'Paired sFRC requires at least two frames. Use a multi-frame TIFF or set singleFrame=true.');
end
FRC=sFRC(image,'pixelSize',pixelSize,'singleFrame',singleFrame,...
    'threshold',threshold,...
    'batchProcessing',batchProcessing);
% FRC now contains the numerical results; the remaining sections are optional.

%% 3. Optional compact summary display
summary=[FRC.summary];
summaryTable=struct2table(summary);
if ismember('resolution_nm',summaryTable.Properties.VariableNames)
    summaryTable=movevars(summaryTable,'resolution_nm','Before',1);
end
disp(summaryTable);

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
plot_sfrc_results(FRC,singleFrame,directory);
if saveResults, fprintf('Results saved to: %s\n',directory); end
