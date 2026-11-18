function figures = plot_sfsc_results(XY, Z, plotFittingCurve, directory)
% Display completed sFSC resolutions/DRI fit and optionally save PNG previews.
% An empty directory displays figures without writing files.
if nargin < 3, plotFittingCurve = false; end
if nargin < 4, directory = ''; end
figures = {};
if ~isfinite(Z.zResolution), return; end
theta = linspace(0, 2*pi, 200);
a = 1000/XY.xyResolution;
b = 1000/Z.zResolution;
radius = 1000*sqrt(cos(theta).^2/a^2 + sin(theta).^2/b^2);
fig = figure('Name', 'sFSC - lateral/axial resolution', 'NumberTitle', 'off');
polarplot(theta, radius, 'Color', [230 115 115]/255, 'LineWidth', 1.5);
title(sprintf('sFSC - lateral/axial resolution; E_DRI=%.2f%%', 100*Z.E_DRI));
% Match Python's one-decimal XY/Z reporting, positioned at the lower right.
% Figure-normalized coordinates keep the labels fixed when the polar axes resize.
annotation(fig, 'textbox', [0.70 0.035 0.27 0.095], ...
    'String', sprintf('XY: %.1f nm\nZ: %.1f nm', ...
        XY.xyResolution, Z.zResolution), ...
    'Units', 'normalized', 'HorizontalAlignment', 'right', ...
    'VerticalAlignment', 'middle', 'FontSize', 11, ...
    'FontWeight', 'bold', 'BackgroundColor', 'white', ...
    'EdgeColor', 'none', 'FitBoxToText', 'off');
figures{end+1} = fig;
if ~isempty(directory)
    saveas(fig, fullfile(directory, 'sFSC_lateral-axial-resolution.png'));
end
if plotFittingCurve
    fig = figure('Name', 'sFSC - DRI elliptical fit', 'NumberTitle', 'off');
    scatter(Z.validX, Z.validY); hold on;
    x = linspace(0, a, 100);
    plot(x, b*sqrt(max(0, 1-x.^2/a^2)), 'Color', [230 115 115]/255);
    xlim([0 a]); ylim([0 max(a,b)]);
    xlabel('Spatial frequency XY (1/um)'); ylabel('Spatial frequency Z (1/um)');
    title(sprintf('sFSC - DRI elliptical fit; E_DRI=%.2f%%', 100*Z.E_DRI));
    figures{end+1} = fig;
    if ~isempty(directory)
        saveas(fig, fullfile(directory, 'sFSC_DRI-elliptical-fit.png'));
    end
end
end
