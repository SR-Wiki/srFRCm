function map = rolling_pair(first,second,spacing,threshold,params)
[h,w]=size(first); block=params.blocksize; skip=params.skip;
first=padarray(first,[block/2 block/2],'symmetric'); second=padarray(second,[block/2 block/2],'symmetric');
rowStarts=1:skip:h; pieces=cell(1,numel(rowStarts));
useParallel=params.parallel && license('test','Distrib_Computing_Toolbox');
if useParallel
    parfor i=1:numel(rowStarts)
        pieces{i}=rolling_row(first,second,rowStarts(i),w,spacing,threshold,params);
    end
else
    for i=1:numel(rowStarts)
        pieces{i}=rolling_row(first,second,rowStarts(i),w,spacing,threshold,params);
    end
end
map=zeros(h,w,'single');
for i=1:numel(rowStarts)
    y=rowStarts(i); height=min(skip,h-y+1);
    map(y:y+height-1,:)=pieces{i}(1:height,:);
end
end
