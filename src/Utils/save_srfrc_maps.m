function save_srfrc_maps(directory, result)
% Save one float32 TIFF and one compact CSV per background group.
if isempty(directory), return; end
if ~isfolder(directory), mkdir(directory); end
count = size(result.maps, 3);
description = ['srFRC resolution map; value unit=nm; page order=input frame/pair order; ' ...
    'summary_statistics=pre_upsampling'];
for settingIndex = 1:numel(result.backgroundRatios)
    setting = result.summary((settingIndex-1)*count + 1).background_setting;
    imwritestack(result.maps(:,:,:,settingIndex), ...
        fullfile(directory, ['srFRC_' setting '_resolution-map.tif']), description);
    rows=result.summary((settingIndex-1)*count+(1:count));
    writetable(struct2table(rows),fullfile(directory,['srFRC_' setting '_results.csv']));
end
end
