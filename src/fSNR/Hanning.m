function [ hanning ] =  Hanning( w, h )
% [ hanning ] = Hanning(height, width)
% Separable two-dimensional Hann window; dimensions follow image (Y,X).
alpha = 0.5;
beta = 1-alpha;

xv = alpha - beta * cos (2*pi/(w-1)*(0:1:(w-1)));
yv = alpha - beta * cos (2*pi/(h-1)*(0:1:(h-1)));

hanning = (yv')*xv;
hanning = hanning';
end