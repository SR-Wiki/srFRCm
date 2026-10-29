function figures = plot_srfrc_results(result, directory)
% Monitor mode: show only three matching resolution maps in one subplot row.
% Every map, including non-monitor mode, has a right-side resolution colorbar.
% All displayed cutoff values are absolute intensities on the 0-255 scale.
% Each setting also receives its own sjet PNG when directory is nonempty.
if nargin<2, directory=''; end
if ~isempty(directory) && ~isfolder(directory), mkdir(directory); end
count=size(result.maps,3);
settings=numel(result.backgroundRatios);
if size(result.maps,4)~=settings || (result.parameters.monitorChange && settings~=3)
    error('srFRC:IncompleteBackgroundGroups',...
        'Monitor mode requires all three background groups. Recompute with the current srFRC.m.');
end
selected=current_result_index(count,result.parameters);
figures=cell(1,numel(selected));
colors=sjet();
for outputIndex=1:numel(selected)
    frame=selected(outputIndex);
    label=result.summary(frame).frame;
    titleText=['srFRC - resolution map - ' label];
    if settings>1, titleText=[titleText ' - background comparison']; end
    monitor=result.parameters.monitorChange && settings==3;
    fig=figure('Name',titleText,'NumberTitle','off',...
        'Position',[80 80 420*settings 480]);
    figures{outputIndex}=fig;
    values=result.maps(:,:,frame,:);
    finiteValues=values(isfinite(values) & values>0);
    upper=1;
    if ~isempty(finiteValues), upper=max(finiteValues); end
    limits=[0 double(upper)];
    for settingIndex=1:settings
        row=result.summary((settingIndex-1)*count+frame);
        setting=row.background_setting;
        ax=subplot(1,settings,settingIndex,'Parent',fig);
        data=result.maps(:,:,frame,settingIndex);
        draw_map(ax,data,colors,limits,label,row.background_threshold);
        if ~isempty(directory)
            filename=fullfile(directory,['srFRC_' label '_' setting '_resolution-map.png']);
            save_preview(filename,data,colors,limits,...
                ['srFRC - resolution map - ' label],row.background_threshold);
        end
    end
    if monitor
        sgtitle(fig,titleText,...
            'Interpreter','none');
    end
end
end

function draw_map(ax,data,colors,limits,label,background)
% Apply the same sjet palette and display range to every comparison axis.
artist=imagesc(ax,data);
set(artist,'Tag','srFRCResolutionMap');
axis(ax,'image'); axis(ax,'off');
colormap(ax,colors); caxis(ax,limits);
bar=colorbar(ax); bar.Label.String='Resolution (nm)';
title(ax,{label,sprintf('Background threshold = %.1f',background)},'Interpreter','none');
end

function save_preview(filename,data,colors,limits,label,background)
% Export an individual setting without changing or closing the comparison window.
fig=figure('Visible','off','NumberTitle','off');
cleanup=onCleanup(@()close(fig)); %#ok<NASGU>
ax=axes('Parent',fig);
draw_map(ax,data,colors,limits,label,background);
saveas(fig,filename);
end
