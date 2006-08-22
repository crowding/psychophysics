function f = staircase(x, n)

%a stair function of adjustable steepness - looks like x when steepness =
%0, looks like floor(x) when steepness is large.

%this is one acceptable function, but is very slow...
%{

%Mathematica derivation:
%
% c = Assuming[Re[n] > 0,  1/Integrate[ x^n * (1 - x)^n, {x, 0, 1}]];
% >>> Gamma[2 + 2*n]/Gamma[1 + n]^2
% f = Integrate[ c * x^n * (1 - x)^n, x]
% >>> (x*(-((-1 + x)*x))^n*Gamma[2 + 2*n]*Hypergeometric2F1[1 + n, -n, 2 + n, x])/((1 + n)*(1 - x)^n*Gamma[1 + n]^2)

%matlab implementation:
adj = floor(x);
x = x - adj;

c = gamma(2+2.*n)./gamma(1+n).^2;
% c*(x*(-((-1 + x)*x))^n*Hypergeometric2F1[1 + n, -n, 2 + n, x])/((1 + n)*(1 - x)^n)

factor = (x.*(-((-1 + x).*x)).^n)./((1 + n).*(1 - x).^n);
% c*factor*Hypergeometric2F1[1 + n, -n, 2 + n, x]

hyp = hypergeom([1+n, -n], 2+n, x);
% c*factor*hyp

f = c.*factor.*hyp;

f = f + adj;

%}

%this one is faster: reflecting x^n around appropriately

adj = round(x);
x = x - adj;
sn = sign(x);
x = x .* sn;

fact = 2.^(n-1);
f = x.^n .* fact;
f = f.*sn + adj;