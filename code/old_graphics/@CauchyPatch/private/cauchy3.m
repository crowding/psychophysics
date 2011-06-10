% [z]  = cauchy3(x, y, t, mu, sigma, order, omega, phase)
% 
% evaluate a horizontal, 3-d spatiotemporal filter at the coordinates given.
% 
% Inputs:
% x, y, t -- Coordinates to evaluate; should be vectors 
%                                     (as in the input to meshgrid().)
% mu -- the center of the filter (a 3-vector).
% sigma -- the spatiotemporal extent of the filter (a 3-vector)
% order -- the order of the filter.
% omega -- the angular velocity used to rotate the filter in quadrature 
%          around t=0.
% phase -- the relative phase.
%
% outputs:
% z -- the evaluated filter. Array of size [length(x) length(y) length(t)].
%      In the x direction the filter is a Cauchy function of the specified 
%      order and extent sigma(1).
%      In the y and t directions the filter is given a Gaussian envelope of
%      standard deviations sigma(2) and sigma(3).
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

function z = cauchy3(x, y, t, mu, sigma, order, omega, phase)

%input checks
if ( (~isvector(x)) || (~isvector(y)) || (~isvector(t)) ) 
	error( 'Coordinates should be given as vectors' );
end

if ( (length(mu) ~= 3) || (length(sigma) ~= 3) ) 
	error( 'mu and sigma should be 3-vectors' );
end

if ( (~isscalar(order)) || (~isscalar(omega)) )
	error( 'order and omega should be scalars' );
end

%separable components of the filter
theta = atan((x - mu(1))/sigma(1));
zx = cos(theta).^order .* exp(i * order * theta + i*phase);
zy = exp(-((y - mu(2))/sigma(2)).^2);
zt = exp(-((t - mu(3))/sigma(3)).^2) .* exp(i*omega*(t - mu(3)));

%putting them together.
z = reshape(cartprod( zy, real( cartprod( zx, zt ) ) ), [length(zy) length(zx) length(zt)]);
