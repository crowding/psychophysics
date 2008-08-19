function [v, t]=movingavg(x,m,t)
% Moving average
% 
% v=movingavg(x,m,t)
%
% x is the timeseries.
% m is the window length.
% v is the variance.

n=size(x,1);
f=zeros(m,1)+1/m;

v=filter2(f,x);
t = filter2(f,t);
m2=floor(m/2);
n2=ceil(m/2);
v=v([zeros(1,m2)+m2+1,(m2+1):(n-n2),zeros(1,n2)+(n-n2)],:);
t=t([zeros(1,m2)+m2+1,(m2+1):(n-n2),zeros(1,n2)+(n-n2)],:);

return
