function [firstIntercept] =  findIntercept(data,threshold)
%   [firstIntercept] =  FindFirstiIntercept(data,threshold)
%
%   Calculates the first intercept abscissa between data (non strictly
%   decraising) and a given threshold curve.

nSamples = size(data,1);
nSamples1 = size(data,2);
assert(nSamples == size(threshold,1) || nSamples1 == size(threshold,1), 'nSamples != size(threshold,1)');
nSamples = max(nSamples, nSamples1);
firstIntercept = -1;

for sample = 4 : nSamples-2
        if	data(sample) < min([threshold(sample), threshold(sample+1), threshold(sample+2)])  && ...
                ( max( [data(sample-1), data(sample-2), data(sample-3)] ) > threshold(sample))
            % Return the detected MATLAB sample index unchanged.
            firstIntercept = sample;
            break;
        end
end

end