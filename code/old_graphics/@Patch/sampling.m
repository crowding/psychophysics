function [x, y, t] = sampling(dispatch, this, cal, pot)
%function [x, y, t] = sampling(dispatch, this, cal)
% Compute appropriate points for sampling this function when computing a movie.
% You can override this for more speed in e.g. a bar stimulus so that the 
% function is only computed at its edges.
%
% The 'dispatch' argument is required due to yet another fundamental failing in 
% how MATLAB implements classes. I need to implement thisclasses that 
% both overload 'sampling' and call this base class's 'sampling'. But this 
% base class's 'sampling' depends on 'extent' and 'resolution' which are
% implemented by thisclasses. Therefore the following:
%
% sampling(this.Patch, cal)
%
% will not work as a way for a thisclass to delegate to this base class. The 
% solution here is to add the 'dispatch' argument and write
%
% sampling(dispatch.Patch, this, cal)
%
% in thisclasses.

[xi, yi, ti] = extent(this);

%everything should be evaluated at integer multiples of pixels and frames.
%calibration gives physical space between pixels, we want degrees (at center)
native = [spacing(cal) cal.interval];
minspac = max(resolution(this), native);
skips = round(minspac ./ native);

spac = native .* skips; %skip integer numbers of pixels and frames

xi = xi/spac(1);
yi = yi/spac(2);
ti = ti/spac(3);

xi = [floor(xi(1)) ceil(xi(2))];
yi = [floor(yi(1)) ceil(yi(2))];
ti = [floor(ti(1)) ceil(ti(2))];

if exist('pot', 'var') && pot
    xi = makepot(xi);
    yi = makepot(yi);
end
    
x = (xi(1):xi(2))*spac(1);
y = (yi(1):yi(2))*spac(2);
t = (ti(1):ti(2))*spac(3);

function i = makepot(i)
    potdiff = round(2.^ceil(log2(i(2) - i(1))) - i(2) + i(1)) - 1;
    i(1) = i(1) - floor(potdiff/2);
    i(2) = i(2) + ceil(potdiff/2);
end

end