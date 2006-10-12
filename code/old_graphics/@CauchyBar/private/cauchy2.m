% [z]  = cauchy2(x, t, mu, sigma, phase, order, omega)
% 
% evaluate a Cauchy function in x modulated by a rotation and Gaussian function
% in t.
% 
% Inputs:
% x, y, t -- Coordinates to evaluate; should be vectors 
%                                     (as in the input to meshgrid().)
% mu -- the center of the filter (a 2-vector).
% sigma -- the spatiotemporal extent of the filter (a 2-vector)
% order -- the order of the filter.
% omega -- the angular velocity used to rotate the filter in quadrature 
%          around t=0.
%
% outputs:
% z -- the evaluated filter. Array of size [length(x) length(t)].
% 
% The Fourier transform of a Cauchy filter is a scaled Poisson.
% The peak frequency of the filter is order/sigma;
% The mean spatial frequency is given by (order+1) / sigma(1).
% The variance of the spatial frequency is (order+1) / sigma(1)^2.
% (Klein and Levi, 1985)
%
% What are the moments of the magnitude of the spatial distribution?
%
% The "velocity" (dx/dt) of the peak spatial frequency is then 
% omega * sigma / order.
%
% The output is normalized with the peak of magnitude 1
% (the real component is even, imaginary component is odd.)

function z = cauchy3(x, t, mu, sigma, phase, order, omega);

%input checks
if ( (~isvector(x)) || (~isvector(t)) ) 
	error( 'Coordinates should be given as vectors' );
end

if ( (length(mu) ~= 2) || (length(sigma) ~= 2) ) 
	error( 'mu and sigma should be 2-vectors' );
end

if ( (~isscalar(order)) || (~isscalar(omega)) )
	error( 'order and omega should be scalars' );
end

%separable components of the filter
theta = atan((x - mu(1))/sigma(1));
zx = cos(theta).^order .* exp(i * order * theta);
zt = exp(-((t - mu(2))/sigma(2)).^2) .* exp(i*(omega*(t - mu(2)) + phase));

%putting them together.
z = reshape(real( cartprod( zx, zt ) ), [length(zx) length(zt)]);
