function [FSC] =  FSCAnalysis(im1, im2, varargin)

% [result] =  FRCAnalysis (im1, im2, varargin)
%
% Performs FRC analysis on two images. If images are 3D, FRC is computed for each
% plane.
%
% Input arguments:
%   im1:                2D or 3D matrix containing photon counts of the first
%                       measurement
%   im2:                2D or 3D matrix containing photon counts of the second
%                       measurement
%
% Varargin:
%   pixelSize           (default 0.025 um)
%   driftCorrection:    if true, perform drift correction before FRC
%                       analysis (default false);
%   meanFilterWidth:    radius of the mean filter used to perform smooth
%                       the FRC curve (default 3 frequency bins);
%   maxIterations:      maximum iterations for the gaussian fitting
%                       performed when applying drift detection algoritm (default 200)
%   roiRadius:          radius of the crosscorrelation function considered for gaussian fitting
%                       when applying drift detection algoritm (default 5 pixels)
%   theta:              if set, for each ring split the FRC analysis for pixels in the
%                       frequency domain for which -theta < angle < +theta
%                       (0 rad). 0 <= theta <= (pi/2)
%   title:              the title of the displayed image
%
%
% Output parameters:
%   result:             struct containing all parameters and result of the
%                       FRC analysis
%
% History
% Version 1.0
% Date: 11/06/2017
%
% Authors: Giorgio Tortarolo, Marco Castello, Giuseppe Vicidomini
% Molecular Microscopy and Spectroscopy
% Istituto Italiano di Tecnologia, Genoa, Italy


% Resolve shared spherical-FSC numerical helpers for direct cryo-EM usage.
% No need to run sFSC first. Keep any outside MATLAB path unchanged.
fSNRDir=fileparts(mfilename('fullpath'));
srcDir=fileparts(fSNRDir);
projectRoot=fileparts(srcDir);
oldFscPath=path;
fscPathCleanup=onCleanup(@()path(oldFscPath)); %#ok<NASGU>
addpath(fullfile(srcDir,'Utils'),'-begin');
addpath(fSNRDir,'-begin');
required={'performFSC','spherical_sum','meanFilter','get_resolution', ...
          'findIntercept','apply_correction'};
for ii=1:numel(required)
    expected=fullfile(fSNRDir,[required{ii} '.m']);
    actual=which(required{ii});
    if ~strcmpi(actual,expected)
        error('FSCAnalysis:DependencyShadowing', ...
            'Expected %s, found %s for %s.',expected,actual,required{ii});
    end
end

%   Default parameters
params.pixelSize = 0.0325;
params.meanFilterWidth = 3;
params.imgName = '';
params.shift_type = 'None';

if nargin > 2
    params =  read_params(params, varargin);
end

try
    %check if the two images have same dimension and are squared
    assert( length(size(im1)) == length(size(im2)),...
        'MATLAB:differentDimensions', 'length(size(im1)) != length(size(im2)');
    assert(nnz( size(im1) == size(im2) ) == length(size(im1)),...
        'MATLAB:differentSizes', 'size(im1) != size(im2)');
    [h, w, d] = size(im1);
    assert( h == w && w == d, 'MATLAB:nonSquared','h != w');
    
    im1 = single(im1);
    im2 = single(im2);
    N = size(im1,1);  %   Number of pixels
    
    if mod(N,2)==0
        Scale = (0:(N/2-1))/(params.pixelSize*N);
    else
        Scale = (0:(N/2))/(params.pixelSize*N);
    end
    
    Scale = Scale';
    Hm = Hanning_3D(N,N,N); %   Hanning window
    
    
%     tmpIm1 = gpuArray(im1);
%     tmpIm2 = gpuArray(im2);
%     fftA = fftshift(fftn(tmpIm1 .* Hm));
%     fftB = fftshift(fftn(tmpIm2 .* Hm));
    fftA = fftshift(fftn(im1 .* Hm));
    fftB = fftshift(fftn(im2 .* Hm));
    FSC =  performFSC(fftA, fftB, params.pixelSize);
catch ME
    rethrow (ME);
end
end



