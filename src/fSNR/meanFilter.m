function [ smoothData ] =  meanFilter (data, mean_width)
%   [ smoothData ] =  meanFilter (data, mean_width)
%   Smooth data using a moving mean filter of (2 * mean_width +1) elements

d = max(size(data));
% disp(['d = ', num2str(d)]);
% disp(['data size(1) = ', num2str(size(data,1))]);
% disp(['data size(2) = ', num2str(size(data,2))]);
% disp(['mean width = ', num2str(mean_width)]);
smoothData = zeros(d,1,'single');

for i = 1 : d
    if  i <= mean_width
        smoothData(i) = mean( data( 1 : i + mean_width ) );
    elseif i > mean_width && i < d-mean_width
        smoothData(i) = mean( data( i - mean_width : i + mean_width ) );

    elseif i >= d-mean_width
        smoothData(i) = mean( data( i - mean_width : d ) );
    end

end
end

