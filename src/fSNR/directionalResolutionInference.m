function [b, validAngles, validResolutions, validX, validY, E_DRI, info] = directionalResolutionInference(im1, im2, a, varargin)
%DIRECTIONALRESOLUTIONINFERENCE Fit the anisotropic resolution ellipse.
%
% All measured directions are checked before any automatic 1/7 extrapolation.

params.pixelSize = [0.0325, 0.0325, 0.0325];
params.meanFilterWidth = 3;
params.windowType = 'Hanning';
params.zSampling = false;
params.lowAngle = pi/12;
params.highAngle = pi/3;
params.num_cones = 5;
params.singleFrame = true;
params.threshold = '1/7 hard threshold';
params.order = 1;
params.progress = true;
if ~isempty(varargin)
    params = read_params(params, varargin);
end
params.threshold=correlation_threshold(params.threshold,'DRI');

b = NaN;
validAngles = [];
validResolutions = [];
validX = [];
validY = [];
E_DRI = NaN;
info=struct('extrapolationAttempted',false,'extrapolationUsedCount',0,'measuredCrossingCount',0,'xyCutoff',a,'zCutoff',NaN);

if ~isequal(size(im1), size(im2))
    error('DRI:DifferentSizes', 'The two input volumes must have the same size.');
end
if numel(params.pixelSize) ~= 3 || any(~isfinite(params.pixelSize)) || any(params.pixelSize <= 0)
    error('DRI:InvalidPixelSize', 'pixelSize must contain three positive finite values.');
end
if ~(isfinite(a) && a > 0)
    error('DRI:InvalidXYCutoff', 'The lateral cutoff frequency must be positive and finite.');
end
if ~(params.lowAngle >= 0 && params.highAngle <= pi/2 && params.lowAngle < params.highAngle)
    error('DRI:InvalidAngles', 'Angles must satisfy 0 <= lowAngle < highAngle <= pi/2.');
end
if ~isnumeric(params.num_cones) || ~isscalar(params.num_cones) || ~isreal(params.num_cones) || ...
        ~isfinite(params.num_cones) || params.num_cones<=0 || params.num_cones~=fix(params.num_cones)
    error('DRI:InvalidConeCount', 'num_cones must be a positive integer.');
end
if ~ismember(params.threshold, {'1/7', '3-sigma'})
    error('DRI:InvalidThreshold', 'threshold must be ''1/7'' or ''3-sigma''.');
end

maxSpacing = max(params.pixelSize);
minSpacing = min(params.pixelSize);
downsamplingFactor = maxSpacing / minSpacing;
tmp_im1 = sampling_xy_skip(im1, downsamplingFactor);
tmp_im2 = sampling_xy_skip(im2, downsamplingFactor);
pixelSize = maxSpacing;
[tmp_im1, ~] = pad2cube(tmp_im1, 1);
[tmp_im2, ~] = pad2cube(tmp_im2, 1);
fftA = fftshift(fftn(tmp_im1));
fftB = fftshift(fftn(tmp_im2));
[h,w,d] = size(tmp_im1);
xc = ceil((w+1)/2);
yc = ceil((h+1)/2);
zc = ceil((d+1)/2);
rMax = min([w-xc, h-yc, d-zc]) + 1;

xg = -w/2+1:w/2;
yg = -h/2+1:h/2;
zg = -d/2+1:d/2;
[X, Y, Z] = meshgrid(xg, yg, zg);
radius = sqrt(X.^2 + Y.^2 + Z.^2);
zenith = asin(abs(Z ./ radius));
zenith(~isfinite(zenith)) = 0;

if params.num_cones==1
    anglesAll=(params.lowAngle+params.highAngle)/2;
    step=params.highAngle-params.lowAngle;
else
    anglesAll=linspace(params.lowAngle,params.highAngle,params.num_cones);
    step=anglesAll(2)-anglesAll(1);
end
resolutions = NaN(1, params.num_cones);
extrapolationRequiredCount = 0;
extrapolationUsedCount = 0;
sectors=cell(1,params.num_cones);
progressBar=[];
if params.progress, progressBar=waitbar(0,'Computing directional crossings...','Name','sFSC - DRI directional FSC'); end
cleaner = onCleanup(@() close_if_valid(progressBar)); 

for i = 1:params.num_cones
    if ~isempty(progressBar), waitbar(i/params.num_cones,progressBar,'Computing directional crossings...'); end
    mask = double(abs(zenith - anglesAll(i)) <= step/2);
    mask(~isfinite(mask)) = 0;
    tmpFSC = fsc(fftA .* mask, fftB .* mask, pixelSize, rMax, X, ...
        params.meanFilterWidth, mask, params.zSampling, params.threshold);

    if params.singleFrame
        res = tmpFSC.resolutionCorrected;
    else
        res = tmpFSC.resolution;
    end

    sectors{i}=tmpFSC;
    resolutions(i) = res;
end

info.measuredCrossingCount=nnz(isfinite(resolutions) & resolutions>0);
if info.measuredCrossingCount==0
    for i=1:params.num_cones
        [resolutions(i),sectors{i},~,used,attempted]=resolve_frc_curve(...
            sectors{i},params.singleFrame,params.threshold,true);
        info.extrapolationAttempted=info.extrapolationAttempted || attempted;
        info.extrapolationUsedCount=info.extrapolationUsedCount+double(used);
    end
end
valid=isfinite(resolutions) & resolutions>0;
if nnz(valid)==0
    warning('sFSC:DRINoCrossing',...
        'No usable directional threshold crossing was found after fallback. Axial resolution is unavailable (NaN). Check the voxel calibration, threshold, and fitting angles; automatic extrapolation is available only for 1/7.');
    [~,guidance]=dri_interpretation(NaN); fprintf('E_DRI unavailable; %s\n',guidance);
    return;
end
if info.extrapolationUsedCount>0
    fprintf('sFSC - axial: Automatic 1/7 extrapolation provided %d directional crossing(s), after all measured directions had no crossing.\n',info.extrapolationUsedCount);
end

angles = anglesAll(valid);
cutoffs = 1000 ./ resolutions(valid);
x = cutoffs .* cos(angles);
y = cutoffs .* sin(angles);
validX = x;
validY = y;

n = numel(cutoffs);
validAngles = zeros(1, 4*n);
validResolutions = zeros(1, 4*n);
for i = 1:n
    validAngles(4*i-3:4*i) = [angles(i), pi-angles(i), angles(i)+pi, 2*pi-angles(i)];
    validResolutions(4*i-3:4*i) = repmat(1000/cutoffs(i), 1, 4);
end

wgt = x.^params.order ./ (sqrt(x.^2 + y.^2).^params.order + 1e-4);
top = wgt .* y.^2 .* (1 - x.^2/a^2);
bot = wgt .* y.^4;
den = sum(bot(:));
if ~(isfinite(den) && den > 0)
    warning('DRI:UnstableFit', 'The directional samples could not produce a stable DRI fit. Check the fitting angles and voxel calibration.');
    return;
end
k = sum(top(:)) / den;
if ~(isfinite(k) && k > 0)
    warning('DRI:InvalidFit', 'The DRI fit did not provide a positive, finite axial cutoff. Check the fitting angles and lateral resolution.');
    return;
end

b = 1000 * sqrt(k);  % axial resolution in nm
kz = 1000 / b;
x1 = linspace(0, a, 100);
y1 = kz .* sqrt(max(0, 1 - x1.^2 ./ a^2));
kFit = 1 ./ sqrt(cos(angles).^2 ./ a.^2 + sin(angles).^2 ./ kz.^2);
E_DRI = calculate_DRI_gof(cutoffs,kFit,angles);
[state,guidance,advice]=dri_interpretation(E_DRI);
fprintf('E_DRI = %.2f%% (%s); %s\n',100*E_DRI,state,guidance);
if ~isfinite(E_DRI) || E_DRI>=0.10
    warning('sFSC:DRIGoodnessOfFit',...
        'E_DRI=%.2f%% (%s). %s. An E_DRI above 20%% means the axial estimate should not be accepted. %s',100*E_DRI,state,guidance,advice);
end
info.zCutoff=kz;

end

function close_if_valid(h)
if ~isempty(h) && isgraphics(h)
    close(h);
end
end

function [FSC] = fsc(tmp_fftA, tmp_fftB, pixelSize, rMax, X, meanFilterWidth, pre_mask, zSampling, threshold)
nominator = tmp_fftA .* conj(tmp_fftB);
denominator1 = abs(tmp_fftA).^2;
denominator2 = abs(tmp_fftB).^2;
top = spherical_sum(nominator, 1);
de1 = spherical_sum(denominator1, 1);
de2 = spherical_sum(denominator2, 1);
denominator = sqrt(de1.*de2);
FSC.num_pixels = spherical_sum(ones(size(X)).*pre_mask, 1);
FSC.rMax = rMax;
FSC.FSC = abs(top) ./ (denominator+eps);
FSC.FSC = refine(removeOutlier(FSC.FSC(1:rMax)));
FSC.FSCCorrected = apply_correction(FSC.FSC);
FSC.smoothedFSC = meanFilter(FSC.FSC, meanFilterWidth);
FSC.smoothedFSCCorrected = meanFilter(FSC.FSCCorrected, meanFilterWidth);
FSC.smoothedFSCCorrected = apply_correction(FSC.smoothedFSC);
if zSampling
    fsc = FSC.smoothedFSCCorrected;
    FSC.smoothedFSCCorrected = 2.*fsc./(1+fsc);
end

K1 = (1/(pixelSize*2))/rMax;
frequence = 1:rMax;
frequence = frequence.';
FSC.frequence = frequence * K1;
FSC.fixedThreshold = 1/7 .* ones(size(frequence));
FSC.threeSigma = 3 ./ (sqrt(FSC.num_pixels./2));
FSC.threeSigma(FSC.threeSigma>1)=1;
FSC.threeSigma = FSC.threeSigma(1:rMax);
[FSC.idxFixed, FSC.fixedResolution] = get_resolution(FSC.frequence, FSC.smoothedFSC, FSC.fixedThreshold);
[FSC.idxThreeSigma, FSC.threeSigmaResolution] = get_resolution(FSC.frequence, FSC.smoothedFSC, FSC.threeSigma);
[FSC.idxFixedCorrected, FSC.fixedResolutionCorrected] = get_resolution(FSC.frequence, FSC.smoothedFSCCorrected, FSC.fixedThreshold);
[FSC.idxThreeSigmaCorrected, FSC.threeSigmaResolutionCorrected] = get_resolution(FSC.frequence, FSC.smoothedFSCCorrected, FSC.threeSigma);
if strcmp(threshold, '1/7')
    FSC.resolution = FSC.fixedResolution;
    FSC.resolutionCorrected = FSC.fixedResolutionCorrected;
else
    FSC.resolution = FSC.threeSigmaResolution;
    FSC.resolutionCorrected = FSC.threeSigmaResolutionCorrected;
end
end

function normal = removeOutlier(abnormal)
normal = abnormal;
normal(isnan(normal) | isinf(normal)) = 1;
end

% tackle abnormal conditions (e.g. no voxels)
function refined = refine(pre)
refined = pre;
idx = find(pre==max(pre), 1);
if idx > 1
    k = (1-max(pre))/(idx-1);
    x = 1:idx-1;
    refined(1:idx-1)=1-k*x;
end
end



function E_DRI = calculate_DRI_gof(k_measured, k_fit, theta)
% calculate_DRI_gof
% Calculate the weighted relative goodness-of-fit error for DRI.
%
% Inputs
%   k_measured : measured directional cutoff frequencies
%   k_fit      : cutoff frequencies predicted by the fitted DRI model
%   theta      : central angles of the directional cones, in radians
%
% Output
%   E_DRI      : weighted relative RMS fitting error
%
% Definition:
%
%              sum_i w_i * ((k_measured_i - k_fit_i) / k_fit_i)^2
% E_DRI = sqrt( ------------------------------------------------------ )
%                              sum_i w_i
%
% where w_i = cos(theta_i).

    % Convert inputs to column vectors
    k_measured = k_measured(:);
    k_fit      = k_fit(:);
    theta      = theta(:);

    % Check input sizes
    if ~(numel(k_measured) == numel(k_fit) && ...
         numel(k_fit) == numel(theta))
        error('k_measured, k_fit, and theta must have the same length.');
    end

    % Angular weights
    % theta is measured relative to the lateral plane
    w = cos(theta);

    % Weighted relative squared residuals
    relative_residual = (k_measured - k_fit) ./ k_fit;

    % Goodness-of-fit error
    E_DRI = sqrt( ...
        sum(w .* relative_residual.^2) / sum(w) ...
        );

end