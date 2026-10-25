function [extended,frequencyExtended,info] = extrapolateFRCCurve_v2(curve,newLength,frequency)
curve=double(curve(:)); frequency=double(frequency(:));
n=numel(curve);
if n<4 || numel(frequency)~=n || newLength<n || frequency(end)<=0
    error('FRC:InvalidCurve','Invalid curve/frequency lengths or frequency range.');
end
x=frequency/frequency(end); y=min(max(curve,1e-6),1-1e-6);
p=polyfit(x.^2,log(y./(1-y)),1);
initial=[min(max(p(2),-30),30),log(max(-p(1),1e-6))];
model=@(q,t) 1./(1+exp(min(700,max(-700,exp(q(2))*t.^2-q(1)))));
objective=@(q) sum((model(q,x)-y).^2);
options=optimset('Display','off','MaxIter',5000,'MaxFunEvals',10000);
[q,~,flag]=fminsearch(objective,initial,options);
usedFallback=flag<=0 || any(~isfinite(q));
if usedFallback, q=initial; end
step=median(diff(frequency));
frequencyExtended=[frequency; frequency(end)+step*(1:newLength-n).'];
extended=model(q,frequencyExtended/frequency(end));
extended(1:n)=curve;
fitted=model(q,x); residual=curve-fitted;
rmse=sqrt(mean(residual.^2)); total=sum((curve-mean(curve)).^2);
r2=NaN; if total>0, r2=1-sum(residual.^2)/total; end
info=struct('A',exp(q(1)),'k',exp(q(2)),'R2',r2,'RMSE',rmse,'usedFallback',usedFallback);
end
