function [im_filtered, preFFT, postFFT] = frcFiltering(im, FWHM)
[h,w,~] = size(im);
%% filtering
ratio = FWHM;
x = -w/2+1:w/2;
y = -h/2+1:h/2;
R = max(h,w);
if h > w
    x = x.*h/w;
end
if w > h
    y = y.*w/h;
end
ratio = 1/FWHM;
[X, Y] = meshgrid(x, y);
radius = sqrt(X.^2+Y.^2);
filterCutoff = floor(R/2*ratio);
im_filtered = zeros(size(im));
for i = 1:size(im, 3)
    mask = ones(size(im(:,:,i)));
    mask(radius>filterCutoff) = 0;
    preFFT = fftshift(fft2(im(:,:,i)));
    postFFT = preFFT.*mask;
    temp = real(ifft2(ifftshift(postFFT)));
    temp(temp<0) = 0;
    im_filtered(:,:,i) = temp;
end
end