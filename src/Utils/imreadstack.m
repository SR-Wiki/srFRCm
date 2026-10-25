function data = imreadstack(filename)
% Read TIFF pages directly to single, then normalize the entire stack by its maximum.
info=imfinfo(filename);
data=zeros(info(1).Height,info(1).Width,numel(info),'single');
for k=1:numel(info)
    data(:,:,k)=single(imread(filename,k));
end
data=normalize_image(data);
end
