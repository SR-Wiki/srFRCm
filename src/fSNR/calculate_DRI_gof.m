function E_DRI = calculate_DRI_gof(k_measured, k_fit, theta)
% calculate_DRI_gof
% Calculate the weighted relative goodness-of-fit error for DRI.
%
% Inputs
%   k_measured : measured directional cutoff frequencies
%   k_fit      : cutoff frequencies predicted by the fitted DRI model
%   theta      : central angles of the directional cones, in radians
%
% Output
%   E_DRI      : weighted relative RMS fitting error
%
% Definition:
%
%              sum_i w_i * ((k_measured_i - k_fit_i) / k_fit_i)^2
% E_DRI = sqrt( ------------------------------------------------------ )
%                              sum_i w_i
%
% where w_i = cos(theta_i).

    % Convert inputs to column vectors
    k_measured = k_measured(:);
    k_fit      = k_fit(:);
    theta      = theta(:);

    % Check input sizes
    if ~(numel(k_measured) == numel(k_fit) && ...
         numel(k_fit) == numel(theta))
        error('k_measured, k_fit, and theta must have the same length.');
    end

    if any(~isfinite(k_measured)) || any(~isfinite(k_fit)) || any(k_fit<=0)
        E_DRI=NaN; return;
    end

    % Angular weights
    % theta is measured relative to the lateral plane
    w = cos(theta);

    % Weighted relative squared residuals
    relative_residual = (k_measured - k_fit) ./ k_fit;

    % Goodness-of-fit error
    E_DRI = sqrt( ...
        sum(w .* relative_residual.^2) / sum(w) ...
        );

end