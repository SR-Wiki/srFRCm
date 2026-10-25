function [refined] = refine(pre)
refined = pre;
idx = find(pre==max(pre), 1);
if idx > 1
    k = (1-max(pre))/(idx-1);
    x = 1:idx-1;
    refined(1:idx-1)=1-k*x;
end
for i = 2:max(size(pre))-1
    if refined(i) < 1e-4
        if refined(i-1) > 0.9 && refined(i+1) > 0.9
            refined(i) = 1;
        end
    end
end
end