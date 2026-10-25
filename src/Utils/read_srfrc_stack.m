function data = read_srfrc_stack(filename)
% Read TIFF pages directly to single, then normalize the entire stack by its maximum.
info=imfinfo(filename);
data=zeros(info(1).Height,info(1).Width,numel(info),'single');
for k=1:numel(info)
    data(:,:,k)=single(imread(filename,k));
end
% Keep the loader independent of the numerical support path.
if any(~isfinite(data(:)))
    error('srFRC:NonfiniteImage','Image intensities must be finite.');
end
maximum=max(data(:));
if maximum~=0, data=data./maximum; end
end
