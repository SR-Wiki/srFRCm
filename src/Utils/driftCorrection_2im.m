function [output] = driftCorrection_2im(im1, im2)
% assert(length(size(im1)) == 3, 'Input should be a 3D image!');
[ox, oy] = size(im1(:,:,1));
dimen = max(ox, oy);
output = zeros(size(im1));
for i = 1:size(im1, 3)
    curMax = max(im2(:,:,i), [], 'all');
    [~, Shift] = DriftDetect(im1(:,:,i), im2(:,:,i), 'maxIterations', 200, 'roiRadius', 5);
    [xF,yF] = meshgrid(-floor(dimen/2):-floor(dimen/2)+dimen-1,...
    -floor(dimen/2):-floor(dimen/2)+dimen-1); %Define shift in frequency domain
    fftB = fftshift(fft2(im2(:,:,i)));
    fftB = fftB.*exp(-1i*2*pi.*((-xF*Shift(1))/ox+(-yF*Shift(2))/oy))+eps; %Perform the shift
    B = abs(real(ifft2(ifftshift(fftB))));
    output(:,:,i) = curMax.*B./max(max(B));
end
output = squeeze(output);
end