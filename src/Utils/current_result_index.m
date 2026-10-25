function index = current_result_index(count,parameters)
% Locate the single current-frame preview while retaining every numerical result.
% currentFrame is one-based. Paired mode uses it with the following frame.
if ~parameters.batchProcessing
    if count>0, index=1; else, index=[]; end
    return;
end
frame=parameters.currentFrame;
if isnumeric(frame) && isscalar(frame) && isreal(frame) && isfinite(frame) && ...
        frame==fix(frame) && frame>=1 && frame<=count
    index=frame;
else
    index=[];
    if parameters.singleFrame
        detail='Choose a valid one-based currentFrame.';
    else
        detail='The current frame needs a following frame for a paired preview.';
    end
    fprintf('No current-frame plot is available. %s All computed batch results are retained.\n',detail);
end
end
