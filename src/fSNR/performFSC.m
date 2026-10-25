function FSC =  performFSC(fftA, fftB, pixelSize, zSampling)
if nargin < 4
    zSampling = false;
end
meanFilterWidth = 3;
[h,w,d] = size(fftA);
xc = ceil((w+1)./2);
yc = ceil((h+1)./2);
zc = ceil((d+1)./2);
rMax = min([w - xc, h - yc, d-zc]) + 1;

x = -w/2+1:w/2;
y = -h/2+1:h/2;
z = -d/2+1:d/2;
[X, ~, ~] = meshgrid(x, y, z);

num_pixels = spherical_sum(ones(size(X)),1);
nominator = fftA .* conj(fftB);
denominator1 = abs(fftA).^2;
denominator2 = abs(fftB).^2;
top = spherical_sum(nominator, 1);
de1 = spherical_sum(denominator1, 1);
de2 = spherical_sum(denominator2, 1);
denominator = sqrt(de1.*de2);


R = 1:rMax;
FSC.FSC = abs(top) ./ (denominator+eps);
FSC.FSC = FSC.FSC(1:rMax);
FSC.FSC = refine(removeOutlier(FSC.FSC));
threeSigma = 3 ./ (sqrt(num_pixels./2));
threeSigma(threeSigma>1)=1;
fiveSigma = 5 ./ (sqrt(num_pixels./2));
fiveSigma(fiveSigma>1)=1;

FSC.threeSigma = threeSigma(1:rMax);
FSC.fiveSigma = fiveSigma(1:rMax);
FSC.num_pixels = num_pixels(1:rMax);
FSC.smoothedFSC = meanFilter(FSC.FSC, meanFilterWidth);
FSC.smoothedFSCCorrected = apply_correction(FSC.smoothedFSC);
if zSampling
    t = FSC.smoothedFSC;
    FSC.smoothedFSC = 2.*t./(1+t);
    t = FSC.smoothedFSCCorrected;
    FSC.smoothedFSCCorrected = 2.*t./(1+t);
end
frequence = R;
n1 = max(size(frequence));
K1 = (1/(pixelSize*2))/n1;
FSC.frequence = frequence*K1;
FSC.fixedThreshold = 1/7 * ones(size(frequence));
[FSC.idxFixed, FSC.fixedResolution] = get_resolution(FSC.frequence, FSC.smoothedFSC, FSC.fixedThreshold);
[FSC.idxThreeSigma, FSC.threeSigmaResolution] = get_resolution(FSC.frequence, FSC.smoothedFSC, FSC.threeSigma);
[FSC.idxFiveSigma, FSC.fiveSigmaResolution] = get_resolution(FSC.frequence, FSC.smoothedFSC, FSC.fiveSigma);
[FSC.idxFixedCorrected, FSC.fixedResolutionCorrected] = get_resolution(FSC.frequence, FSC.smoothedFSCCorrected, FSC.fixedThreshold);
[FSC.idxThreeSigmaCorrected, FSC.threeSigmaResolutionCorrected] = get_resolution(FSC.frequence, FSC.smoothedFSCCorrected, FSC.threeSigma);
[FSC.idxFiveSigmaCorrected, FSC.fiveSigmaResolutionCorrected] = get_resolution(FSC.frequence, FSC.smoothedFSCCorrected, FSC.fiveSigma);
FSC.fiveSigmaResolutionCorrected = FSC.fiveSigmaResolutionCorrected * 3/5;
FSC.fiveSigmaResolution = FSC.fiveSigmaResolution * 3/5;
end