function [corrected, ad] = apply_correction(single_frc)
h=2*size(single_frc, 1);
w=2*size(single_frc, 1);
corrected = zeros(h/2,1);
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
ad = zeros(w/2,1);
point = -1;

for r = 1:w/2
    ring_set = round(X.^2+Y.^2) == r.^2;
%     re = mean(Re(ring_set), 'all');
%     a = mean(A(ring_set), "all");
    cur_div = mean(div(ring_set), 'all');
    ad(r) = cur_div;
    tmp = single_frc(r);
    if cur_div <= 1 || point > 0
        corrected(r) = single_frc(r);
    else
        corrected(r) = (cur_div*tmp+eps)/(1+(cur_div-1)*tmp+eps);
    end
%         if threshold < 0
%             threshold = r;
%             disp(['Correction threshold: Normalized = ', num2str(r*2/w)]);
%         end
%     end
%     corrected(r) = (cur_div*tmp+eps)/(1+(cur_div-1)*tmp+eps);
    if (corrected(r)<=1/7+eps)
%         if point < 0
%             disp(['Ending factor:', num2str(cur_div)]);
%         end
        point = r;
        corrected(r+1:end) = single_frc(r+1:end);
        break;
    end  
end
% if point > 0
%     corrected(point-10:end) = movmean(corrected(point-10:end), 3);
% end
corrected(corrected>1) = 1;
corrected(corrected<0) = 0;
end