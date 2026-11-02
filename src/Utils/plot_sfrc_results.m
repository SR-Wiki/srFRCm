function figures = plot_sfrc_results(curves, singleFrame, directory)
% Display only the first-frame sFRC curve and optionally save its PNG preview.
% An empty directory displays figures without writing files.
if nargin < 3, directory = ''; end
selected=current_result_index(numel(curves));
figures = cell(1, numel(selected));
for outputIndex = 1:numel(selected)
    index=selected(outputIndex);
    label = curves(index).summary.frame;
    fig = plot_correlation_curve(curves(index), singleFrame, ...
        curves(index).summary.threshold, ['sFRC - correlation curve - ' label]);
    figures{outputIndex} = fig;
    if ~isempty(directory)
        saveas(fig, fullfile(directory, ['sFRC_' label '_correlation-curve.png']));
    end
end
end
