function [result]=spherical_sum(data,radial_step)
%main axii cpecified:
x=(1:size(data,2))-size(data,2)/2;
y=(1:size(data,1))-size(data,1)/2;
z=(1:size(data,3))-size(data,3)/2;
% coordinate grid:
[X,Y,Z]=meshgrid(x,y,z);
% creating circular layers
Z_integer=round(sqrt(X.^2+Y.^2+Z.^2)/radial_step)+1;
result=accumarray(Z_integer(:),data(:),[],@sum);
end