function [im_filtered, preFFT, postFFT] = frcFiltering3D(im, pixelSize, xyFWHM, zFWHM)

%% filtering
%% TO DO: Elliptical Filtering
[h,w,d] = size(im);
xRatio = 2*pixelSize(2)/xyFWHM;
yRatio = 2*pixelSize(1)/xyFWHM;
zRatio = 2*pixelSize(3)/zFWHM;
xLimit = w/2*xRatio;
yLimit = h/2*yRatio;
zLimit = d/2*zRatio;
x = -w/2+1:w/2;
y = -h/2+1:h/2;
z = -d/2+1:d/2;
[X,Y,Z] = meshgrid(x,y,z);

% ellipse function
ellipse = (X.^2./(xLimit*xLimit) + Y.^2./(yLimit*yLimit) + Z.^2./(zLimit*zLimit));
clear X Y Z;

mask = ones(size(im));
mask(ellipse>1) = 0;
preFFT = fftshift(fftn(im));
postFFT = preFFT.*mask;

im_filtered = real(ifftn(ifftshift(postFFT)));
im_filtered(im_filtered<0) = 0;
end










