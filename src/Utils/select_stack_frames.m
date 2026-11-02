function selected = select_stack_frames(frames,singleFrame,batchProcessing)
%SELECT_STACK_FRAMES Return all valid frame/pair indices, or just the first.
if ~isscalar(batchProcessing) || ~(islogical(batchProcessing) || isnumeric(batchProcessing)) || ...
        ~isreal(batchProcessing) || ~isfinite(batchProcessing) || ~ismember(batchProcessing,[0 1])
    error('Analysis:InvalidBatchProcessing','batchProcessing must be true or false.');
end
available=frames-double(~singleFrame);
if available<1
    if singleFrame
        error('Analysis:ImagePairRequired','The input stack is empty. Provide at least one image.');
    end
    error('Analysis:ImagePairRequired','Paired mode needs at least two frames in the input stack.');
end
if batchProcessing
    selected=1:available;
else
    selected=1;
end
end
