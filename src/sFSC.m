function [FSCXY, FSCZ] = sFSC(im, varargin)
% **************************************************************************************
% Single-volume FSC (sFSC): lateral and axial resolution from directional inference.
% **************************************************************************************
% Usage:
%   [FSCXY,FSCZ] = sFSC(volume, 'pixelSize', [0.03 0.03 0.1]);
%   [FSCXY,FSCZ] = sFSC(volume1, volume2, 'singleFrame', false);
%   [FSCXY,FSCZ] = sFSC(cat(4,volume1,volume2), 'singleFrame', false);
% -----------------------------------------------
% Input:
%   im                 Numeric volume (Y,X,Z) in single-frame mode.
%                      Paired mode accepts (Y,X,Z,2), or a second numeric volume
%                      before the name-value parameters. Both volumes must match.
% Name-value parameters:
%   pixelSize          Positive voxel spacings [x y z] in um.
%                      {default: [0.03 0.03 0.1]}
%   meanFilterWidth    Correlation smoothing radius in bins. {default: 3}
%   singleFrame        Generate an XY-resampled pair from one volume. {default: true}
%   threshold          '1/7 hard threshold' or '3-sigma'; '1/7' remains an alias.
%                      {default: '1/7 hard threshold'}
%   zSampling          Manually enable odd/even Z sampling. {default: false}
%                      This option is never selected automatically from spacing.
%   lowAngle           Lower DRI fitting angle in radians. {default: pi/12}
%                      Recommended >10 degrees, i.e. >pi/18 radians.
%   highAngle          Upper DRI fitting angle in radians. {default: pi/3}
%                      Recommended <80 degrees, i.e. <4*pi/9 radians.
%   numCones           Positive integer directional-cone count. {default: 5}
%                      At least 5 is recommended; smaller positive counts are valid.
%   xyMode             Lateral analysis from 'slice' or '3D' FFT data.
%                      {default: 'slice'}
%   progress           Show the computation progress display. {default: true}
%   motionCorrection   Align paired volumes before analysis. {default: false}
%   weighted           Retained compatibility flag; currently unused. {default: false}
% -----------------------------------------------
% Output:
%   FSCXY              Lateral resolution structure with xyResolution in nm
%                      and the selected lateral FRC data when available.
%   FSCZ               Axial result with zResolution in nm, valid angular/cutoff
%                      samples, E_DRI, fitInfo, parameters, and summary.
%                      E_DRI is a relative fraction; summary.E_DRI_percent is percent.
%                      Unavailable resolution and fit-error values are NaN.
%                      FSCZ.computationSeconds and stageComputationSeconds
%                      report numerical timing before any demo plots/export.
% -----------------------------------------------
% Notes:
%   Inputs are converted to single and divided by their maximum before sampling.
%   Each stack/volume shares its maximum; an all-zero input remains zero.
%   Input voxel spacings are in um; reported resolutions are in nm.
%   Single-frame input is one volume; paired input requires singleFrame=false.
%   DRI extrapolation is attempted only when every measured direction has no usable
%   threshold crossing. Automatic curve extrapolation supports '1/7' only.
%   E_DRI <10%: reliable; 10-20%: use with caution; >20%: unacceptable.
%   For a high E_DRI, try adjusting the DRI fitting angle range and rerun.
%   If axial resolution appears overly optimistic, manually enable zSampling
%   and compare the resulting estimates.
%   Plotting and result-file exports are controlled by the demo, not this function.
%   Every call appends the complete E_DRI grading guide on exit, including early
%   returns and errors, independently of plotting.
% **************************************************************************************

% Shared FRC numerical helpers have one canonical implementation in
% src/fSNR; other utilities live in src/Utils.
projectRoot=fileparts(fileparts(mfilename('fullpath')));
originalDependencyPath=path;
dependencyPathCleanup=onCleanup(@()path(originalDependencyPath)); %#ok<NASGU>
% Current global FRC uses the one five-input implementation in src/fSNR.
% In v9 fSNR was appended at the END of the MATLAB path; a different
% performFRC could therefore be called, causing 'Too many input arguments'.
% Add src/Utils and prioritize the FRC/FSC core in src/fSNR.
addpath(fullfile(projectRoot,'src','Utils'),'-begin');
addpath(fullfile(projectRoot,'src','fSNR'),'-begin');
check_global_frc_paths(projectRoot,'sFSC');

[~,driGuidance] = dri_interpretation(NaN);
driGuidanceCleanup = onCleanup(@() fprintf('sFSC - E_DRI guidance: %s\n',driGuidance)); %#ok<NASGU>

params.pixelSize = [0.03, 0.03, 0.1]; % [x y z], um
params.meanFilterWidth = 3;
params.xyMode = 'slice';
params.weighted = false;
params.singleFrame = true;
params.zSampling = false; % Enable manually with zSampling, true.
params.lowAngle = pi/12;
params.highAngle = pi/3;
params.numCones = 5;
params.threshold = '1/7 hard threshold';
params.progress=true;
params.motionCorrection=false;
computationTic=tic;
lateralTic=computationTic; % Includes input preparation and lateral estimation.
im=normalize_image(im);
if ~isempty(varargin) && isnumeric(varargin{1})
    im=cat(4,im,normalize_image(varargin{1})); varargin=varargin(2:end);
end
params=read_params(params,varargin);
params.threshold=correlation_threshold(params.threshold,'sFSC');
originalPixelSize=params.pixelSize;
params.zSampling=resolve_z_sampling(params.zSampling);
originalParameters=params;
if params.singleFrame
    if ndims(im)>3, error('sFSC:InvalidVolume','Single-frame mode expects one (Y,X,Z) volume.'); end
    height=2*floor(size(im,1)/2); width=2*floor(size(im,2)/2);
    stack=diagonal_resample(double(im(1:height,1:width,:)));
    im1=stack(:,:,:,1); im2=stack(:,:,:,2);
    params.pixelSize(1:2)=params.pixelSize(1:2)*2;
else
    if ndims(im)~=4 || size(im,4)<2, error('sFSC:PairedVolumesRequired','Paired mode expects (Y,X,Z,2) or two volumes.'); end
    im1=double(normalize_image(im(:,:,:,1))); im2=double(normalize_image(im(:,:,:,2)));
    if params.motionCorrection, im2=driftCorrection_2im(im1,im2); end
end
if ~isequal(size(im1), size(im2))
    error('sFSC:DifferentSizes', 'The two input volumes must have the same size.');
end
if numel(params.pixelSize) ~= 3 || any(~isfinite(params.pixelSize)) || any(params.pixelSize <= 0)
    error('sFSC:InvalidPixelSize', 'pixelSize must contain three positive finite values [x y z].');
end
if params.meanFilterWidth < 1
    error('sFSC:InvalidMeanFilterWidth', 'meanFilterWidth must be >= 1.');
end
if ~ismember(params.xyMode, {'slice', '3D'})
    error('sFSC:InvalidXYMode', 'xyMode must be ''slice'' or ''3D''.');
end
if ~(isfinite(params.lowAngle) && isfinite(params.highAngle) && ...
        params.lowAngle >= 0 && params.highAngle <= pi/2 && params.lowAngle < params.highAngle)
    error('sFSC:InvalidAngles', 'Angles must satisfy 0 <= lowAngle < highAngle <= pi/2.');
end
if ~isnumeric(params.numCones) || ~isscalar(params.numCones) || ~isreal(params.numCones) || ...
        ~isfinite(params.numCones) || params.numCones<=0 || params.numCones~=fix(params.numCones)
    error('sFSC:InvalidConeCount', 'numCones must be a positive integer.');
end
if ~ismember(params.threshold, {'1/7', '3-sigma'})
    error('sFSC:InvalidThreshold', 'threshold must be ''1/7'' or ''3-sigma''.');
end

spacingRatio = max(params.pixelSize) / min(params.pixelSize);
if spacingRatio >= 10
    warning('sFSC:StrongSamplingAnisotropy', ...
        ['Sampling is strongly anisotropic (largest/smallest spacing = %.1fx). ', ...
         'Please verify the voxel calibration.'], spacingRatio);
end
if params.lowAngle<=pi/18 || params.highAngle>=4*pi/9
    warning('sFSC:FittingAngleRange',...
        'Recommended DRI fitting angles: lowAngle > 10 degrees and highAngle < 80 degrees. MATLAB lowAngle/highAngle are in radians.');
end

lateralAttempted=false;
FSCXY = struct();
FSCZ = struct();
[h,w,d] = size(im1); 

%% Lateral resolution
fprintf('sFSC - lateral: estimating resolution...\n');
selectedExtrapolated = false;
extrapolationRequired = false;
if strcmp(params.xyMode, 'slice')
    if d <= 20
        planesXY = 1:d;
    else
        planesXY = unique(selectPlanes(im1, 20));
    end
    minRes = Inf;
    progressBar=[];
    if params.progress, progressBar=waitbar(0,'Computing lateral resolution...','Name','sFSC - lateral resolution'); end
    cleaner = onCleanup(@() close_if_valid(progressBar)); 
    for j = 1:numel(planesXY)
        i = planesXY(j);
        if ~isempty(progressBar), waitbar(j/numel(planesXY),progressBar,'Computing lateral resolution...'); end
        fftA = fftshift(fft2(pad2square(im1(:,:,i))));
        fftB = fftshift(fft2(pad2square(im2(:,:,i))));
        curFRC = performFRC(fftA, fftB, params.pixelSize(1), ...
            params.meanFilterWidth, params.threshold);
        [res,curFRC,required,used,attempted]=resolve_frc_curve(curFRC,params.singleFrame,params.threshold);
        lateralAttempted=lateralAttempted || attempted;
        extrapolationRequired = extrapolationRequired || required;
        if isfinite(res) && res < minRes
            minRes = res;
            FSCXY.plane = i;
            FSCXY.FRC = curFRC;
            selectedExtrapolated = used;
        end
    end
    close_if_valid(progressBar);
    if ~isfield(FSCXY, 'FRC')
        report_missing_lateral(extrapolationRequired, params);
        FSCXY.xyResolution = NaN;
        FSCZ=unavailable_result(lateralAttempted,originalParameters);
        FSCZ=attach_sfsc_timing(FSCZ,computationTic,toc(lateralTic),0);
        return;
    end
    FSCXY.xyResolution = minRes;
    fprintf('Selected plane is %d\n', FSCXY.plane);
else
    Hn = Hanning_3D(h,w,d);
    fftA = fftshift(fftn(im1 .* Hn));
    fftB = fftshift(fftn(im2 .* Hn));
    zc = ceil((d+1)/2);
    curFRC = performFRC(fftA(:,:,zc), fftB(:,:,zc), params.pixelSize(1), ...
        params.meanFilterWidth, params.threshold);
    [FSCXY.xyResolution,curFRC,extrapolationRequired,selectedExtrapolated,lateralAttempted]=...
        resolve_frc_curve(curFRC,params.singleFrame,params.threshold);
    FSCXY.FRC = curFRC;
    if ~isfinite(FSCXY.xyResolution)
        report_missing_lateral(extrapolationRequired, params);
        FSCZ=unavailable_result(lateralAttempted,originalParameters);
        FSCZ=attach_sfsc_timing(FSCZ,computationTic,toc(lateralTic),0);
        return;
    end
end

if selectedExtrapolated
    % Candidate lateral slices are evaluated silently. Only the extrapolation
    % fit associated with the finally selected plane is reported.
    if isfield(FSCXY, 'FRC') && isfield(FSCXY.FRC, 'extrapolationFitInfo') && ...
            ~isempty(FSCXY.FRC.extrapolationFitInfo)
        info = FSCXY.FRC.extrapolationFitInfo;
        suffix = '';
        if isfield(info, 'usedFallback') && info.usedFallback
            suffix = ' [linearized fallback]';
        end
        fprintf(['sFSC - lateral curve extrapolation fit: A=%.6g, k(norm)=%.6g, ', ...
                 'R^2=%.4f, RMSE=%.4g%s\n'], ...
                 info.A, info.k, info.R2, info.RMSE, suffix);
    end
    fprintf('sFSC - lateral: automatic 1/7 extrapolation used; result includes an extrapolated estimate.\n');
end
fprintf('XY Resolution = %.3f nm\n', FSCXY.xyResolution);

lateralSeconds=toc(lateralTic);
axialTic=tic;
%% Axial resolution
fprintf('sFSC - axial: estimating resolution with DRI...\n');
analysisPixelSize = params.pixelSize;
if params.zSampling
    maxDepth = min(size(im1,3), size(im2,3));
    maxDepth = maxDepth - mod(maxDepth,2);
    im1 = im1(:,:,1:2:maxDepth-1);
    im2 = im2(:,:,2:2:maxDepth);
    analysisPixelSize(3) = 2 * analysisPixelSize(3);
end

maxSpacing = max(analysisPixelSize);
minSpacing = min(analysisPixelSize);
if analysisPixelSize(3) < analysisPixelSize(1)
    downsamplingFactor = maxSpacing / minSpacing;
    im1 = sampling_3d_skip(im1, downsamplingFactor);
    im2 = sampling_3d_skip(im2, downsamplingFactor);
    analysisPixelSize(3) = analysisPixelSize(1);
end

[FSCZ.zResolution, FSCZ.validAngles, FSCZ.validResolutions, ...
    FSCZ.validX, FSCZ.validY, FSCZ.E_DRI, driInfo] = ...
    directionalResolutionInference(im1, im2, 1000/FSCXY.xyResolution, ...
    'pixelSize', analysisPixelSize, ...
    'lowAngle', params.lowAngle, 'highAngle', params.highAngle, ...
    'num_cones', params.numCones, 'singleFrame', params.singleFrame, ...
    'zSampling', params.zSampling, 'threshold', params.threshold, ...
    'progress',params.progress,'meanFilterWidth',params.meanFilterWidth);

if ~isfinite(FSCZ.E_DRI), [~,guidance]=dri_interpretation(NaN); fprintf('E_DRI unavailable; %s\n',guidance); end
FSCZ.extrapolationAttempted=driInfo.extrapolationAttempted;
FSCZ.zSamplingEnabled=params.zSampling;
FSCZ.interpretationNote=sfsc_z_sampling_note(params.singleFrame,params.zSampling,FSCZ.zResolution);
if ~isempty(FSCZ.interpretationNote), fprintf('sFSC - axial: %s\n',FSCZ.interpretationNote); end
stage='none';
if lateralAttempted && driInfo.extrapolationAttempted, stage='lateral and axial';
elseif lateralAttempted, stage='lateral';
elseif driInfo.extrapolationAttempted, stage='axial'; end
summary=struct('singleframe',params.singleFrame,'threshold',params.threshold,...
    'extrapolation_triggered',lateralAttempted || driInfo.extrapolationAttempted,...
    'extrapolation_stage',stage,'lateral_resolution_nm',FSCXY.xyResolution,...
    'axial_resolution_nm',FSCZ.zResolution,'E_DRI_percent',100*FSCZ.E_DRI);
[state,guidance]=dri_interpretation(FSCZ.E_DRI);
FSCZ.summary=summary;
FSCZ.parameters=originalParameters;
FSCZ.fitInfo=driInfo;
FSCZ.E_DRI_guidance=guidance;
FSCZ=attach_sfsc_timing(FSCZ,computationTic,lateralSeconds,toc(axialTic));

end

function report_missing_lateral(required,params)
if required && ~strcmp(params.threshold,'1/7')
    warning('sFSC:UnsupportedExtrapolationThreshold','No lateral threshold crossing was found in the measured range. Automatic extrapolation is available only for 1/7. Check the threshold and voxel calibration.');
else
    warning('sFSC:LateralResolutionUnavailable','Automatic extrapolation could not provide a usable lateral estimate. Axial resolution is unavailable (NaN); check the threshold and voxel calibration.');
end
end

function close_if_valid(h)
if ~isempty(h) && isgraphics(h)
    close(h);
end
end

function axial = unavailable_result(attempted,parameters)
[state,guidance]=dri_interpretation(NaN);
stage='none'; if attempted, stage='lateral'; end
summary=struct('singleframe',parameters.singleFrame,'threshold',parameters.threshold,...
    'extrapolation_triggered',attempted,'extrapolation_stage',stage,...
    'lateral_resolution_nm',NaN,'axial_resolution_nm',NaN,'E_DRI_percent',NaN);
axial=struct('zResolution',NaN,'E_DRI',NaN,'summary',summary,...
    'parameters',parameters,'E_DRI_guidance',guidance,...
    'zSamplingEnabled',parameters.zSampling,'interpretationNote','');
fprintf('E_DRI unavailable (%s); %s\n',state,guidance);
end

function result=attach_sfsc_timing(result,totalTic,lateral,axial)
% Lateral includes input preparation; axial includes Z processing, FFT and DRI.
% The total ends before any demo plotting or export.
result.computationSeconds=toc(totalTic);
result.elapsedSeconds=result.computationSeconds;
result.stageComputationSeconds=struct('lateral',lateral,'axial',axial);
fprintf('sFSC - numerical computation time: %.3f s (excludes demo plotting and export).\n',...
    result.computationSeconds);
fprintf('  lateral: %.3f s; axial: %.3f s\n',lateral,axial);
end
