function groups = background_groups(maps,summary,thresholds,ratios)
% Describe every background group without duplicating the numerical map array.
% maps remains (Y,X,T,B); mapIndex identifies the fourth-dimension slice.
count=size(maps,3);
settings=numel(ratios);
if size(maps,4)~=settings || numel(summary)~=count*settings || ...
        ~isequal(size(thresholds),[count settings])
    error('srFRC:IncompleteBackgroundGroups','Maps, summaries and thresholds must contain every background group.');
end
template=struct('name','','ratio',0,'mapIndex',0,'summary',struct([]),...
    'backgroundThresholds',[]);
groups=repmat(template,1,settings);
for setting=1:settings
    rows=(setting-1)*count+(1:count);
    groups(setting).name=summary(rows(1)).background_setting;
    groups(setting).ratio=ratios(setting);
    groups(setting).mapIndex=setting;
    groups(setting).summary=summary(rows);
    groups(setting).backgroundThresholds=thresholds(:,setting);
end
end
