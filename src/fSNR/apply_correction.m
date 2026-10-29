function [corrected, ad] = apply_correction(single_frc)
% Reuse geometry-only correction factors, preserve early-stop/tail behavior.
h=2*size(single_frc,1);
w=2*size(single_frc,1);
corrected=zeros(h/2,1);
ad=zeros(w/2,1);
persistent cachedN cachedFactors
if isempty(cachedFactors) || isempty(cachedN) || cachedN ~= w/2
    factors=build_correction_factors(w,h);
    cachedN=w/2;
    cachedFactors=factors;
end
point = -1;
for r = 1:w/2
    cur_div = cachedFactors(r);
    ad(r) = cur_div;
    tmp = single_frc(r);
    if cur_div <= 1 || point > 0
        corrected(r) = single_frc(r);
    else
        corrected(r) = (cur_div*tmp+eps)/(1+(cur_div-1)*tmp+eps);
    end
    if corrected(r)<=1/7+eps
        point = r;
        corrected(r+1:end) = single_frc(r+1:end);
        break;
    end
end
corrected(corrected>1)=1;
corrected(corrected<0)=0;
end

function factors=build_correction_factors(w,h)
x = -w/2+1:w/2;
y = -h/2+1:h/2;
[X,Y] = meshgrid(x,y);
theta1 = X*pi/w;
theta2 = Y*pi/h;
Re = real(exp(1i.*theta1)+exp(1i.*theta2));
x1 = 1 + exp(-1i.*(theta1+theta2));
x2 = exp(-1i.*(theta1+theta2)) - 1;
y1 = exp(-1i.*theta1) + exp(-1i.*theta2);
y2 = exp(-1i.*theta1) - exp(-1i.*theta2);
x1=abs(x1).^2; x2=abs(x2).^2; y1=abs(y1).^2; y2=abs(y2).^2;
A = sqrt(x1.*y1+x2.*y2+x1.*y2+x2.*y1);
div = A./Re;
div(isnan(div)) = 0;
div(isinf(div)) = 0;
div(div>5) = 0;
% Match Python/Java's default correction geometry:
%   round(sqrt(X.^2+Y.^2)) == r, for r=1,...,w/2.
% The integer grid cannot have an exactly half-integer nonzero radius,
% so MATLAB round, NumPy rint and Java Math.round select the same bins.
% Build the rounded-radius bins once and accumulate every annulus in one pass.
n = w/2;
radiusBin = round(sqrt(X.^2 + Y.^2));
inside = (radiusBin >= 1) & (radiusBin <= n);
index = radiusBin(inside);
ringSum = accumarray(index(:), div(inside), [n, 1], @sum, 0);
ringCount = accumarray(index(:), ones(numel(index),1), [n, 1], @sum, 0);
factors = ringSum ./ ringCount;
end
