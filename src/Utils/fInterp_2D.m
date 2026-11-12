function img_ip = fInterp_2D_V2(img, newsz)
% Instead if zero-padding, this method pad the fourier image with gaussian
% noise estimated from original border
% Fourier interpolation of 2D image 'img' to new size 'newsz' = [nx,ny]
% This is similar to performing MATLABs interpft along all dimensions
% individually, but faster.
% Fourier interpolation
% Author: Simon Christoph Stein
% E-Mail: scstein@phys.uni-goettingen.de
% Date: 2017
imgsz = size(img);
%  If necessary, increase ny by an integer multiple to make ny > m.
if sum(newsz == 0) >= 1
    img_ip = [];
    return
end
isgreater = newsz >= imgsz;
incr = zeros(2,1);
for iDim = 1:2
    if isgreater(iDim)
        incr(iDim) = 1;
    else
        incr = floor(imgsz(iDim)/newsz(iDim)) + 1;
        newsz(iDim) = incr(iDim)*newsz(iDim);
    end
end
img_ip = zeros(newsz);
nyqst = ceil((imgsz+1)/2);
img = newsz(1)/imgsz(1)*newsz(2)/imgsz(2)* fft2(img);%  multiplicative factor conserves the counts at the original positions
shift_img = fftshift(img);
% [h,w] = size(shift_img);
% x = -w/2+1:w/2;
% y = -h/2+1:h/2;
% [X, Y] = meshgrid(x, y);
% border_mask = X <= (-w/2+5) | Y <= (-h/2+5) | X >= (w/2-5) | Y >= (h/2-5);
% border = shift_img(border_mask);
% border = border(border~=0);
% noise_real = std(real(border));
% noise_imag = std(imag(border));
%% smooth edge effects
shift_img = apodImRect(shift_img, 3);
img = fftshift(shift_img);
% shift_img(border_mask) = shift_img(border_mask) + noise_real.*randn(size(shift_img(border_mask))) + 1i*noise_imag.*randn(size(shift_img(border_mask)));
% img = fftshift(apodImRect(shift_img, 7));
% shift_img = fftshift(img);
% figure;imshow(log(1+abs(fftshift(img))),[]);


% border_line = X == (-w/2+3) | Y == (-h/2+3) | X == (w/2-3) | Y == (h/2-3);
% figure;imshow(border_line, []);

% border = shift_img(border_mask);
% border = border(border~=0);
% noise_real = std(real(border));
% noise_imag = std(imag(border));
% img_ip = img_ip + noise_real.*randn(size(img_ip)) + 1i*noise_imag.*randn(size(img_ip));
% zero padding, need to copy all 4 edges of the image plane
% note: xl:'x low', xh:'x high'
img_ip(1:nyqst(1),1:nyqst(2)) = img(1:nyqst(1),1:nyqst(2)); % xl, yl
img_ip(end-(imgsz(1)-nyqst(1))+1:end, 1:nyqst(2)) = img(nyqst(1)+1:imgsz(1),1:nyqst(2)); % xh, yl
img_ip(1:nyqst(1),end-(imgsz(2)-nyqst(2))+1:end) = img(1:nyqst(1), nyqst(2)+1:imgsz(2)); % xl, yh
img_ip(end-(imgsz(1)-nyqst(1))+1:end, end-(imgsz(2)-nyqst(2))+1:end) = img(nyqst(1)+1:imgsz(1), nyqst(2)+1:imgsz(2)); % xh, yh, zl
rm = rem(imgsz,2);
if rm(1) == 0  && newsz(1) ~= imgsz(1)
    img_ip(nyqst(1), :) = img_ip(nyqst(1), :)/2;
    img_ip(nyqst(1) + newsz(1)-imgsz(1), :) = img_ip(nyqst(1), :);
end
if rm(2) == 0  && newsz(2) ~= imgsz(2)
    img_ip(:, nyqst(2)) = img_ip(:, nyqst(2))/2;
    img_ip(:, nyqst(2) + newsz(2)-imgsz(2)) = img_ip(:, nyqst(2));
end

% smooth padding edge

% img_ip = fftshift(img_ip);
% blurred_img_ip = imfilter(img_ip, g);
% figure;imshow(border_line, []);
% [h,w] = size(img_ip);
% x = -w/2+1:w/2;
% y = -h/2+1:h/2;
% [X, Y] = meshgrid(x, y);
% border_mask = X <= (-w/4+7) | Y <= (-h/4+7) | X >= (w/4-7) | Y >= (h/4-7);
% temp = img_ip(border_mask);
% temp = temp + noise_real.*randn(size(temp)) + 1i*noise_imag.*randn(size(temp));
% img_ip(border_mask) = temp;
% img_ip(border_mask) = blurred_img_ip(border_mask);
% img_ip = apodImRect(img_ip, h+3);
% figure;imshow(log(1+abs(img_ip)), []);
% img_ip = fftshift(img_ip);


img_ip = real(ifft2(img_ip));
% Skip points if neccessary
img_ip = img_ip(1:incr(1):newsz(1), 1:incr(2):newsz(2));
end
