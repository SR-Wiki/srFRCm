function [ out ] =  Hanning_3D(n1, n2, n3)
% Return a symmetrical 3D Hanning window of dimensions n1 x n2 x n3 
% The centre is at the origin [n1/2 n2/2 n3/2] 
% The filtered is scaled such that max(out(:)) = 1 
% 
% Jack J. Miller, University of Oxford 2017 
if ~(isscalar(n1) && isscalar(n2) && isscalar(n3))
    error('Input arguments should be scalar'); 
end
if ((n2 == 1) && (n3 ==1))
    out = hanning(n1); 
elseif n3 == 1 
    out = bsxfun(@times,hanning(n1),hanning(n2).'); 
else
    out = bsxfun(@times,bsxfun(@times,hanning(n1),hanning(n2).'),permute(hanning(n3),[3 2 1])); 
end
out = out./(max(out(:))); 
end

function h = hanning(x) % 1D window of length x
% C.f. https://en.wikipedia.org/wiki/Window_function#Hann_window
% Use the same Hann coefficients along X, Y and Z. 
alpha=0.5; 
beta=1-alpha; 
h = alpha-beta*cos(2*pi*[0:(x-1)]./(x-1)); 
h = h.'; 
end