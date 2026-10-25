function selected = select_stack_frames(frames,singleFrame,batchProcessing,currentFrame)
%SELECT_STACK_FRAMES Return original one-based frame/pair indices.
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
    if ~isnumeric(currentFrame) || ~isscalar(currentFrame) || ~isreal(currentFrame) || ...
            ~isfinite(currentFrame) || currentFrame~=fix(currentFrame) || currentFrame<1 || currentFrame>available
        error('Analysis:InvalidCurrentFrame',...
            'Choose a valid one-based currentFrame. In paired mode, the selected frame must have a following frame.');
    end
    selected=currentFrame;
end
end
