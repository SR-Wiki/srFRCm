function normal = removeOutlier(abnormal)
normal = abnormal;
normal(isnan(normal) | isinf(normal)) = 1;
end