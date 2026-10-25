% Sections 1-2 show the complete input and computation workflow.
% Sections 3-4 demonstrate optional reporting and saving; section 5 displays the result.
%% 1. Input and analysis settings
clear; clc; close all;
demoDir=fileparts(mfilename('fullpath'));
rootDir=fileparts(demoDir);
addpath(fullfile(rootDir,'src'));
addpath(fullfile(rootDir,'src','Utils'));
% Modify dataRoot when the TIFF files are stored outside the repository.
% rootDir='C:\Users\dell\Downloads';
inputFile=fullfile(rootDir,'example_data','Fig4i_1.tif');
secondInputFile=fullfile(rootDir,'example_data','Fig4i_2.tif');
pixelSize=[20 20 60]/1000; % [x y z], um
singleFrame=true;
threshold='1/7 hard threshold'; % Alternative: '3-sigma'.
zSampling=false; % Set true to enable manually.
% Optional demo controls; these are not numerical-function parameters.
plotFittingCurve=false;
saveResults=true;

%% 2. Numerical computation
% sFSC treats the stack as a 3D volume, rather than a batch of 2D frames.
image=imreadstack(inputFile);
pairArguments={};
if ~singleFrame, second=imreadstack(secondInputFile); pairArguments={second}; end
[XY,Z]=sFSC(image,pairArguments{:},'pixelSize',pixelSize,...
    'singleFrame',singleFrame,'zSampling',zSampling,'threshold',threshold);
% XY and Z now contain the numerical results; reporting and saving are optional.

%% 3. Optional compact summary display
summary=Z.summary;
disp(struct2table(summary));

%% 4. Optional numerical-result export
% This demo section owns results/ creation and file writing.
directory=''; % Empty means display without saving previews.
if saveResults
    directory=fullfile(pwd,'results');
    if ~isfolder(directory), mkdir(directory); end
    result=struct('lateral',XY,'axial',Z,'E_DRI_guidance',Z.E_DRI_guidance,...
        'axialResolutionNote',Z.interpretationNote);
    save_demo_summary(directory,'sFSC',result,summary,Z.parameters);
end
%% 5. Resolution display and optional DRI-fit/preview export
% Plotting/preview helpers live in src/Utils/ and consume the completed results.
% Display is always enabled for an available result; no plotResults switch is needed.
plot_sfsc_results(XY,Z,plotFittingCurve,directory);
if saveResults, fprintf('Results: %s\n',directory); end
