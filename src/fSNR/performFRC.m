function [FRC] =  performFRC(fftA, fftB, pixelSize, meanFilterWidth, threshold)
% FRC = performFRC(fftA, fftB, pixelSize, meanFilterWidth, threshold)
%
% Calculates FRC curve; 3Sigma and 5Sigma threshold curves
% Internal criterion is already canonicalized by the public entry points.
% The fixed threshold curve is numerically 1/7; no numeric replacement occurs.
if ~any(strcmp(threshold,{'1/7','3-sigma'}))
    error('performFRC:InvalidThreshold','Internal threshold must be 1/7 or 3-sigma.');
end

[h,w] = size(fftA);
xc = ceil((w+1)./2);
yc = ceil((h+1)./2);
rMax = min( w - xc, h - yc) + 1;

x = -w/2+1:w/2;
y = -h/2+1:h/2;
[X, ~] = meshgrid(x, y);

num_pixels = radial_sum(ones(size(X)),1);
nominator = fftA .* conj(fftB);
denominator1 = abs(fftA).^2;
denominator2 = abs(fftB).^2;
top = radial_sum(nominator, 1);
de1 = radial_sum(denominator1, 1);
de2 = radial_sum(denominator2, 1);
denominator = sqrt(de1.*de2);


R = 1:rMax;
FRC.FRC = abs(top) ./ (denominator+eps);
FRC.FRC = refine(removeOutlier(FRC.FRC(1:rMax)));
threeSigma = 3 ./ (sqrt(num_pixels./2));
threeSigma(threeSigma>1)=1;
fiveSigma = 5 ./ (sqrt(num_pixels./2));
fiveSigma(fiveSigma>1)=1;

FRC.threeSigma = threeSigma(1:rMax);
FRC.fiveSigma = fiveSigma(1:rMax);
FRC.num_pixels = num_pixels(1:rMax);
FRC.smoothedFRC = meanFilter(FRC.FRC, meanFilterWidth);
FRC.smoothedFRCCorrected = apply_correction(FRC.smoothedFRC);

frequence = R;
n1 = max(size(frequence));
K1 = (1/(pixelSize*2))/n1;
FRC.frequence = frequence*K1;
FRC.fixedThreshold = 1/7 * ones(size(frequence));
[FRC.idxFixed, FRC.fixedResolution] = get_resolution(FRC.frequence, FRC.smoothedFRC, FRC.fixedThreshold);
[FRC.idxThreeSigma, FRC.threeSigmaResolution] = get_resolution(FRC.frequence, FRC.smoothedFRC, FRC.threeSigma);
[FRC.idxFiveSigma, FRC.fiveSigmaResolution] = get_resolution(FRC.frequence, FRC.smoothedFRC, FRC.fiveSigma);
[FRC.idxFixedCorrected, FRC.fixedResolutionCorrected] = get_resolution(FRC.frequence, FRC.smoothedFRCCorrected, FRC.fixedThreshold);
[FRC.idxThreeSigmaCorrected, FRC.threeSigmaResolutionCorrected] = get_resolution(FRC.frequence, FRC.smoothedFRCCorrected, FRC.threeSigma);
[FRC.idxFiveSigmaCorrected, FRC.fiveSigmaResolutionCorrected] = get_resolution(FRC.frequence, FRC.smoothedFRCCorrected, FRC.fiveSigma);
FRC.fiveSigmaResolutionCorrected = FRC.fiveSigmaResolutionCorrected * 3/5;
FRC.fiveSigmaResolution = FRC.fiveSigmaResolution * 3/5;
if strcmp(threshold, '1/7')
    FRC.resolution = FRC.fixedResolution;
    FRC.resolutionCorrected = FRC.fixedResolutionCorrected;
else
    FRC.resolution = FRC.threeSigmaResolution;
    FRC.resolutionCorrected = FRC.threeSigmaResolutionCorrected;
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