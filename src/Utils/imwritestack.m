function imwritestack(stack, filename, imageDescription)
% Write float32 TIFF pages without intensity normalization.
% The optional description records units or page order for exported maps.
if nargin < 3, imageDescription = ''; end
t = Tiff(filename, 'w');
cleanup = onCleanup(@() t.close()); %#ok<NASGU>

tagstruct.ImageLength = size(stack, 1);
tagstruct.ImageWidth = size(stack, 2);
tagstruct.Photometric = Tiff.Photometric.MinIsBlack;
tagstruct.BitsPerSample = 32;
tagstruct.SampleFormat = Tiff.SampleFormat.IEEEFP;
tagstruct.SamplesPerPixel = 1;
tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
tagstruct.Compression = Tiff.Compression.None;
if ~isempty(imageDescription)
    tagstruct.ImageDescription = char(imageDescription);
end

for k = 1:size(stack, 3)
    t.setTag(tagstruct);
    t.write(single(stack(:, :, k)));
    if k < size(stack, 3), t.writeDirectory(); end
end
end
