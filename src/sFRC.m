function FRC = sFRC(im,varargin)
% **************************************************************************************
% Single-frame Fourier ring correlation (sFRC) for images and 2D-image stacks.
% **************************************************************************************
% Usage:
%   FRC = sFRC(im, 'pixelSize', 0.02, 'singleFrame', true);
%   FRC = sFRC(stack, 'batchProcessing', false, 'currentFrame', 3);
% -----------------------------------------------
% Input:
%   im                 Numeric image (Y,X) or image stack (Y,X,T).
% Name-value parameters:
%   pixelSize          Positive XY pixel spacing in um. {default: 0.02}
%   meanFilterWidth    Correlation smoothing radius in bins. {default: 3}
%   singleFrame        Generate a diagonal pair from each frame. {default: true}
%                      If false, correlate adjacent overlapping frame pairs.
%   threshold          '1/7 hard threshold' or '3-sigma'; '1/7' remains an alias.
%                      {default: '1/7 hard threshold'}
%   motionCorrection   Align paired frames before correlation. {default: false}
%   batchProcessing    Analyse all frames/pairs. {default: true}
%                      If false, analyse currentFrame only; batch mode ignores it.
%   currentFrame       One-based frame index for an individual run. {default: 1}
%                      Paired mode also requires the following frame.
% -----------------------------------------------
% Output:
%   FRC                Structure or ordered structure array, one per frame/pair.
%                      Each entry contains the numerical correlation data,
%                      original parameters, and a summary with frame, singleframe,
%                      threshold, extrapolation_triggered, and resolution_nm.
% -----------------------------------------------
% Notes:
%   Inputs are converted to single and divided by their maximum before sampling.
%   Each stack/volume shares its maximum; an all-zero input remains zero.
%   Input pixel spacing is in um; reported resolution is in nm.
%   Single-frame sampling uses the even XY region and doubles the analysis spacing.
%   Automatic extrapolation is attempted only for a missing measured 1/7 crossing.
%   This numerical function does not display plots or write result files.
%   The demo controls plotting and optional exports to the current directory results/.
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
check_global_frc_paths(projectRoot,'sFRC');

params=struct('pixelSize',0.02,'meanFilterWidth',3,'singleFrame',true,...
    'threshold','1/7 hard threshold','motionCorrection',false,'batchProcessing',true,'currentFrame',1);
params=read_params(params,varargin);
params.threshold=correlation_threshold(params.threshold,'sFRC');
if ~isscalar(params.pixelSize) || ~isfinite(params.pixelSize) || params.pixelSize<=0
    error('sFRC:InvalidPixelSize','Enter a positive, finite pixelSize in um.');
end
if params.meanFilterWidth<1 || ~ismember(params.threshold,{'1/7','3-sigma'})
    error('sFRC:InvalidSettings','Choose meanFilterWidth >= 1 and threshold ''1/7'' or ''3-sigma''.');
end
if ndims(im)>3, error('sFRC:InvalidStack','Expected (Y,X) or (Y,X,T).'); end
im=normalize_image(im);
selected=select_stack_frames(size(im,3),params.singleFrame,params.batchProcessing,params.currentFrame);
% Keep currentFrame in output metadata for compatibility with plotting
% helpers from older releases. In batch mode it is *not* an input
% selector: all frames/pairs are computed, and 1 means preview the
% first computed result. Never use a user-supplied currentFrame in batch.
if params.batchProcessing, params.currentFrame=1; end
count=numel(selected);
if count<1, error('sFRC:ImagePairRequired','Paired mode needs at least two stack frames.'); end
curves=cell(1,count); rows=cell(1,count);
for index=1:count
    t=selected(index);
    spacing=params.pixelSize;
    if params.singleFrame
        height=2*floor(size(im,1)/2); width=2*floor(size(im,2)/2);
        if min(height,width)<2, error('sFRC:SmallInput','Input must be at least 2 x 2 pixels.'); end
        pair=diagonal_resample(double(im(1:height,1:width,t)));
        im1=pair(:,:,1); im2=pair(:,:,2); spacing=2*spacing;
        label=sprintf('frame%04d',t);
    else
        im1=double(im(:,:,t)); im2=double(im(:,:,t+1));
        if params.motionCorrection, im2=driftCorrection_2im(im1,im2); end
        label=sprintf('pair%04d-%04d',t,t+1);
    end
    im1=pad2square(im1); im2=pad2square(im2);
    curve=performFRC(fftshift(fft2(im1)),fftshift(fft2(im2)),spacing,params.meanFilterWidth,params.threshold);
    [resolution,curve,~,used,attempted]=resolve_frc_curve(curve,params.singleFrame,params.threshold);
    if used
        fprintf('sFRC - %s: No threshold crossing was found in the measured range. Automatic 1/7 extrapolation provided the resolution estimate.\n',label);
    elseif ~isfinite(resolution)
        if strcmp(params.threshold,'1/7')
            warning('sFRC:ResolutionUnavailable','%s: Automatic extrapolation could not provide a usable threshold crossing. Resolution is unavailable (NaN); check the pixel size and threshold.',label);
        else
            warning('sFRC:UnsupportedExtrapolationThreshold','%s: No threshold crossing was found in the measured range. Automatic extrapolation is available only for 1/7. Resolution is unavailable (NaN); check the threshold and pixel size.',label);
        end
    end
    row=struct('frame',label,'singleframe',params.singleFrame,'threshold',params.threshold,...
        'extrapolation_triggered',attempted,'resolution_nm',resolution);
    curve.summary=row; curve.parameters=params;
    rows{index}=row; curves{index}=curve;

end
FRC=[curves{:}];
end
