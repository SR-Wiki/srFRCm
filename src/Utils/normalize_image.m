function data = normalize_image(image)
% Copy finite real image data to single, then divide by one maximum per array.
% A stack/volume shares its maximum, preserving relative slice intensities.
% An all-zero input remains zero. The caller's image is not modified.
if ~(isnumeric(image) || islogical(image)) || ~isreal(image) || isempty(image)
    error('sFRC:InvalidImage','Provide a nonempty, real numeric image, stack or volume.');
end
data=single(image);
if any(~isfinite(data(:)))
    error('sFRC:NonfiniteImage','Image intensities must be finite; remove NaN or infinite values before analysis.');
end
maximum=max(data(:));
if maximum~=0, data=data./maximum; end
end
