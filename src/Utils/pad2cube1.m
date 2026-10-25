function [padded1, padded2] = pad2cube1(im1, im2)


comple = mod(size(im1), 2);
im1 = padarray(im1, comple, 'symmetric', 'post');
im2 = padarray(im2, comple, 'symmetric', 'post');
[h,w,d] = size(im1);
Hn = Hanning_3D(h,w,d);
im1 = im1.*Hn;
im2 = im2.*Hn;
max_dim = max(size(im1));
pad_num = ceil(max_dim/d)-1;
padded1 = im1;
padded2 = im2;
dims = [1, 2, 3];
for i = 1:pad_num
    flip_dim = dims(randi(numel(dims),1,1));
    im1_flip = flip(im1, flip_dim);
    im2_flip = flip(im2, flip_dim);
    if rand < 0.25
        padded1 = cat(3, padded1, im1_flip);
        padded2 = cat(3, padded2, im2_flip);
    elseif rand < 0.5
        padded1 = cat(3, padded1, im1);
        padded2 = cat(3, padded2, im2);
    else
        padded1 = cat(3, padded1, zeros(size(im1)));
        padded2 = cat(3, padded2, zeros(size(im1)));
    end
end

padded1 = 255.*padded1./max(padded1(:));
padded2 = 255.*padded2./max(padded2(:));


end