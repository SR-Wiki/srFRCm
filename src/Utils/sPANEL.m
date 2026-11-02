function [FRCMap,PANELs,RSM,absolute_value,SR_convolve_rsf,threshold] = sPANEL(image,varargin)
%SPANEL Compatibility entry: mapping is now maintained by srFRC.
% Resolve srFRC and packaged helpers without relying on the root utils folder.
utilsFolder=fileparts(mfilename('fullpath'));
sourceFolder=fileparts(utilsFolder);
originalPath=path;
pathCleanup=onCleanup(@() path(originalPath)); %#ok<NASGU>
addpath(sourceFolder,'-begin');
addpath(fullfile(sourceFolder,'Utils'),'-begin');

addpath(fullfile(sourceFolder,'fSNR'),'-begin');

params=struct('pixelSize',0.0325,'skip',2,'blocksize',64,'adaptiveBackground',true,...
    'monitorChange',false,'backgroundIntensity',5,'enableSingleFrame',true,...
    'batchProcessing',true,'parallel',true,'driftCorrection',false,'EnableOtsu',true,...
    'EnableRSM',false,'boundary',true,'amedianfilter',true);
params=read_params(params,varargin);
if isfield(params,'currentFrame')
    error('Analysis:RemovedFrameSelection','currentFrame is no longer supported; the first frame/pair is used.');
end
r=srFRC(image,'pixelSize',params.pixelSize,'singleFrame',params.enableSingleFrame,...
    'batchProcessing',params.batchProcessing,...
    'skip',params.skip,'blocksize',params.blocksize,'adaptiveBackground',params.adaptiveBackground,...
    'monitorChange',params.monitorChange,'backgroundIntensity',params.backgroundIntensity,...
    'motionCorrection',params.driftCorrection,'parallel',params.parallel,...
    'boundary',params.boundary,'amedianfilter',params.amedianfilter);
count=size(r.maps,3); settings=size(r.maps,4);
FRCMap=r.maps;
if count==1, FRCMap=reshape(r.maps,size(r.maps,1),size(r.maps,2),settings); end
threshold=r.backgroundThresholds;
absolute_value=NaN(count,settings,7);
for b=1:settings
    for f=1:count
        row=r.summary((b-1)*count+f);
        absolute_value(f,b,1:4)=[row.rFRC_value row.mean_resolution_nm row.min_resolution_nm row.max_resolution_nm];
    end
end
if count==1, absolute_value=reshape(absolute_value,settings,7); end
RSM=zeros(size(r.maps,1),size(r.maps,2),count,settings,'single');
SR_convolve_rsf=RSM;
PANELs=zeros(size(r.maps,1),size(r.maps,2),3,count,settings,'single');
for b=1:settings
  for f=1:count
    green=r.maps(:,:,f,b); valid=green(isfinite(green) & green>0);
    if ~isempty(valid)
        green=max(0,min(1,green/min(valid)-1));
        if params.EnableOtsu
            green=max(0,green-.4); green(green<graythresh(green)*max(green(:)))=0;
        end
        if max(green(:))>0, green=green/max(green(:)); end
        PANELs(:,:,2,f,b)=green;
    end
end
end
end
