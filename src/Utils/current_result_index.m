function index = current_result_index(count)
%CURRENT_RESULT_INDEX Always preview the first completed frame/pair.
if ~isscalar(count) || ~isnumeric(count) || ~isfinite(count) || count<0 || fix(count)~=count
    error('srFRC:InvalidResultCount','Number of results must be a nonnegative integer.');
end
if count==0
    index=[];
else
    index=1;
end
end
