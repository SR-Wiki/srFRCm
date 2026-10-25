function result = srFRC(im,varargin)
% **************************************************************************************
% Rolling single-frame FRC (srFRC) resolution maps for images and image stacks.
% **************************************************************************************
% Usage:
%   result = srFRC(im, 'pixelSize', 0.02, 'singleFrame', true);
%   result = srFRC(stack, 'batchProcessing', false, 'currentFrame', 3);
% -----------------------------------------------
% Input:
%   im                 Numeric image (Y,X) or image stack (Y,X,T).
% Name-value parameters:
%   pixelSize          Original positive XY pixel spacing in um. {default: 0.02}
%   singleFrame        Generate a diagonal pair from each frame. {default: true}
%                      If false, analyse adjacent overlapping frame pairs.
%   threshold          '1/7 hard threshold' or '3-sigma'. {default: '3-sigma'}
%                      '1/7' remains a fixed-criterion alias; internal sigma fallbacks remain.
%   blocksize          Rolling-window side length in pixels; rounded up to even.
%                      {default: 64}
%   skip               Positive rolling step, capped at blocksize/2. {default: 2}
%   adaptiveBackground Use 1.2 times Otsu; forced false by monitorChange.
%                      {default: true}
%   monitorChange      Compare 0.8, 1.0, and 1.2 times Otsu independently and
%                      force adaptiveBackground=false. {default: false}
%   backgroundIntensity Manual threshold on the normalized 0-255 scale.
%                      Used only when both background switches are false.
%                      {default: 30}
%   batchProcessing    Analyse every frame/pair. {default: true}
%   currentFrame       One-based preview frame; also selects computation when batching is false.
%                      Paired mode also needs the following frame. {default: 1}
%   motionCorrection   Align paired frames before calculation. {default: false}
%   meanFilterWidth    Correlation smoothing radius in bins. {default: 3}
%   parallel           Use parfor if the Parallel Computing Toolbox is available;
%                      otherwise run serially. {default: true}
%   boundary           Apply the local background-intensity mask. {default: true}
%   amedianfilter      Apply adaptive median filtering when skip=1. {default: true}
% -----------------------------------------------
% Output:
%   result.maps        Final single-precision resolution maps in nm, with axes
%                      (Y,X,T,B): analysed frame/pair T and background setting B.
%   result.summary     One structure per analysed frame/pair and background setting;
%                      includes mean/min/max resolution in nm, rFRC_value, and the
%                      final background_threshold on the 0-255 intensity scale.
%                      Resolution statistics use the cleaned map BEFORE upsampling.
%   result.backgroundThresholds  Final thresholds arranged as (T,B).
%   result.backgroundReference  First normalized FRC partner per analysed frame
%                      (at paired-grid resolution) for monitor-mode previews.
%   result.backgroundRatios      Adaptive multipliers, or 0 for manual background.
%   result.backgroundGroups      Named descriptors with mapIndex, per-frame
%                      summaries and thresholds. Group b is maps(:,:,:,b).
%   result.backgroundCount       Exactly 3 in monitor mode, otherwise 1.
%   result.backgroundMode        'monitor', 'automatic', or 'manual'.
%   result.parameters  Effective numerical settings, including the map lower bound.
%   result.mapAxes     'YXTB'; mapInterpolationBackend records cubic_spline
%                      for single-frame restoration, or none for paired mode.
% -----------------------------------------------
% Notes:
%   Inputs are converted to single and divided by their maximum before sampling.
%   Each stack/volume shares its maximum; an all-zero input remains zero.
%   Input pixelSize is in um; reported map values and resolution statistics are nm.
%   Single-frame maps use separable not-a-knot cubic-spline restoration, retaining
%   the measured foreground and bounding positive output to the source range.
%   Non-positive values become background zero. Interpolation can change the mean.
%   Every finite positive final value is at least 2.3 times the original pixel size.
%   Statistics are computed BEFORE restoration, after background cleanup and the
%   original-pixel-size lower bound, using finite positive foreground only.
%   rFRC_value = mean_resolution_nm/min_resolution_nm - 1. Statistics may differ
%   from reductions of the restored display/export map. statisticsStage records
%   pre_upsampling; statisticsMapSize records the native analysis-grid dimensions.
%   Rolling correlations use the chosen primary criterion, followed when needed
%   by 5-sigma x 0.6 then 2-sigma x 1.5. Local curves are not extrapolated.
%   This function does not plot or save files. Demo-controlled exports use results/;
%   demo plots show only currentFrame with batchProcessing true or false.
%   srFRC numerical helpers live in src/fSNR; map, modeling, image and
%   reporting helpers live in src/Utils.
%   No separate srFRC_support or repository-root utils folder is needed.
%   The entry temporarily adds the two support and restores the MATLAB search path on exit.
% **************************************************************************************

srfrcSupportFolder=fileparts(mfilename('fullpath')); 
srfrcOriginalPath=path;
srfrcPathCleanup=onCleanup(@() path(srfrcOriginalPath)); %#ok<NASGU>
% Dependencies reside only in src/fSNR and src/Utils.
addpath(fullfile(srfrcSupportFolder,'Utils'),'-begin');

addpath(fullfile(srfrcSupportFolder,'fSNR'),'-begin');

% Resolve numeric helpers explicitly before doing any calculation. This catches
% functions in the current working directory or former root utils/ shadowing srFRC's
% own implementation (MATLAB gives its current folder path precedence).
assert_srfrc_dependency_paths(srfrcSupportFolder);

params=struct('pixelSize',0.02,'singleFrame',true,'blocksize',64,'skip',2,...
    'threshold','3-sigma',...
    'adaptiveBackground',true,'monitorChange',false,'backgroundIntensity',30,...
    'batchProcessing',true,'currentFrame',1,...
    'motionCorrection',false,'meanFilterWidth',3,'parallel',true,'boundary',true,'amedianfilter',true);
params=read_params(params,varargin);
params.threshold=correlation_threshold(params.threshold);
[params,ratios]=background_settings(params);
if params.monitorChange
    fprintf(['srFRC - background mode: monitorChange=true disables adaptiveBackground. ',...
        'Comparing Otsu multipliers 0.8, 1.0, and 1.2; backgroundIntensity is ignored.\n']);
end
if ~isscalar(params.pixelSize) || ~isfinite(params.pixelSize) || params.pixelSize<=0
    error('srFRC:InvalidPixelSize','Enter a positive, finite pixelSize in um.');
end
if ndims(im)>3 || params.blocksize<2 || params.skip<1
    error('srFRC:InvalidSettings','Provide a 2D image (Y,X) or stack (Y,X,T), with blocksize >= 2 and skip >= 1.');
end
params.blocksize=2*ceil(params.blocksize/2); params.skip=min(params.skip,params.blocksize/2);
params.minimumResolutionNm=2.3*(params.pixelSize*1000);
computationTic=tic; % Numerical computation only; srFRC never draws or exports.
im=normalize_image(im);
[h,w,frames]=size(im);
selected=select_stack_frames(frames,params.singleFrame,params.batchProcessing,params.currentFrame);
count=numel(selected);
if count<1, error('srFRC:ImagePairRequired','Paired mode requires at least two frames.'); end
maps=zeros(h,w,count,numel(ratios),'single'); rows=cell(count*numel(ratios),1);
backgrounds=zeros(count,numel(ratios));
groupComputationSeconds=zeros(1,numel(ratios));
frameComputationSeconds=zeros(count,numel(ratios));
% Cache only one reference per analysed frame in monitor mode. The threshold
% is computed on the first normalized member of the local FRC pair.
% This is display metadata: it never changes the rolling computation.
backgroundReference=cell(1,count);
for r=1:numel(ratios)
    groupTic=tic;
    ratio=ratios(r); setting='manual-bg';
    if params.adaptiveBackground || params.monitorChange, setting=sprintf('bg%.1f',ratio); end
    for index=1:count
        frameTic=tic;
        t=selected(index);
        spacing=params.pixelSize;
        if params.singleFrame
            pair=diagonal_resample(double(im(1:2*floor(h/2),1:2*floor(w/2),t)));
            first=pair(:,:,1); second=pair(:,:,2); spacing=2*spacing;
            label=sprintf('frame%04d',t);
        else
            first=double(im(:,:,t)); second=double(im(:,:,t+1));
            if params.motionCorrection, second=driftCorrection_2im(first,second); end
            label=sprintf('pair%04d-%04d',t,t+1);
        end
        first=double(normalize_image(first));
        second=double(normalize_image(second));
        if params.monitorChange && r==1
            backgroundReference{index}=single(first);
        end
        threshold=params.backgroundIntensity;
        if params.adaptiveBackground || params.monitorChange, threshold=ratio*255*graythresh(uint8(255*first)); end
        data=rolling_pair(first,second,spacing,threshold,params);
        if params.amedianfilter && params.skip==1, data=AMF(data); end
        [data,statistics]=map_statistics(data,params.pixelSize*1000);
        statisticsMapSize=[size(data,1) size(data,2)];
        if params.singleFrame
            data=restore_map_size(data,[h w]);
        end
        maps(:,:,index,r)=data; backgrounds(index,r)=threshold;
        row=struct('frame',label,'background_setting',setting,'singleframe',params.singleFrame,'threshold',params.threshold);
        names=fieldnames(statistics);
        for k=1:numel(names), row.(names{k})=statistics.(names{k}); end
        frameComputationSeconds(index,r)=toc(frameTic);
        row.background_threshold=threshold;
        rows{(r-1)*count+index}=row;

    end
    groupComputationSeconds(r)=toc(groupTic);
end
summary=[rows{:}];
backend='none';
if params.singleFrame
    backend='cubic_spline';
end
result=struct('maps',maps,'summary',summary,'backgroundThresholds',backgrounds,...
    'backgroundReference',{backgroundReference},... % One (Y,X) FRC reference per analysed frame.
    'backgroundRatios',ratios,'pixelSize',params.pixelSize,'mapAxes','YXTB',...
    'mapInterpolationBackend',backend,'statisticsStage','pre_upsampling',...
    'statisticsMapSize',statisticsMapSize,'parameters',params);
result.backgroundGroups=background_groups(maps,summary,backgrounds,ratios);
result.backgroundCount=numel(result.backgroundGroups);
result.backgroundMode=params.backgroundMode;
result.computationSeconds=toc(computationTic);
result.elapsedSeconds=result.computationSeconds;
result.backgroundComputationSeconds=groupComputationSeconds;
result.frameComputationSeconds=frameComputationSeconds;
fprintf('srFRC - numerical computation time: %.3f s (excludes plotting and export).\n',...
    result.computationSeconds);
for groupIndex=1:numel(ratios)
    fprintf('  %s: %.3f s\n',result.backgroundGroups(groupIndex).name,...
        groupComputationSeconds(groupIndex));
end
fprintf('srFRC - completed %d background group(s), %d frame/pair result(s) per group: %s.\n',...
    result.backgroundCount,count,strjoin({result.backgroundGroups.name},', '));
end

function assert_srfrc_dependency_paths(supportFolder)
% Resolve the exact on-disk implementation, not only the function name.
% Do not call clear functions here: doing so from within srFRC may invalidate
% active function state. Fail fast and tell the caller which path to remove.
groups={...
    'fSNR',{'rolling_pair','rolling_row','performFRC','radial_sum',...
            'Hanning','meanFilter','apply_correction','get_resolution',...
            'findIntercept','diagonal_resample','correlation_threshold'};...
    'Utils',{'read_params','normalize_image','background_settings',...
             'select_stack_frames','map_statistics','restore_map_size',...
             'background_groups','driftCorrection_2im','AMF'}...
};
for groupIndex=1:size(groups,1)
    directory=fullfile(supportFolder,groups{groupIndex,1});
    helpers=groups{groupIndex,2};
    for k=1:numel(helpers)
        helper=helpers{k};
        expected=fullfile(directory,[helper '.m']);
        actual=which(helper);
        if ~strcmpi(actual,expected)
            error('srFRC:DependencyShadowing',...
                ['srFRC must use its support implementation for %s.\n'...
                 'Expected: %s\nMATLAB resolves: %s\n'...
                 'Remove the shadowing folder from the current directory/path.'],...
                helper,expected,actual);
        end
    end
end
end
