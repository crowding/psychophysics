% z = evaluate(c, x, y, t)
% Evaluates the patch at the mesh coordinates given.
function z = evaluate(this, x, y, t)

%"sigma" in terms of order and half-wavelength.
% have: size(1) = wavelength;
% want: sigma(1);
sigma = this.size/2;
sigma(1) = this.order*this.size(1)/2/pi;

%"omega" in terms of wavelength and wavefront velocity.
omega = -this.velocity * this.order / sigma(1);

cent = get(this, 'center');

z = real(cauchy2(x, t, cent([1 3]), sigma([1 3]), this.phi, this.order, omega));
box = (y <= (cent(2) + sigma(2))) & (y >= (cent(2) - sigma(2)));
z = reshape(cartprod(box, z), [numel(y) numel(x) numel(t)]);
