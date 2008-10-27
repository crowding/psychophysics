function cp = chisquareintegral(val, df)
% CP = CHISQUAREINTEGRAL(VAL, DF)

% Part of the psignifit toolbox version 2.5.6 for MATLAB version 5 and up.
% Copyright (c) J.Hill 1999-2005.
% Please read the LICENSE and NO WARRANTY statement in psych_legal.m
% mailto:psignifit@bootstrap-software.org
% http://bootstrap-software.org/psignifit/

if nargin == 1
	df = val;
	val = 'plot';
end

if isstr(val)
	if strcmp(lower(val), 'plot')
		if ishold, val = xlim; else val = [0 8*df^0.73]; end	
		val = linspace(min(val), max(val), 300);
% 		compute exp(log(d/dx of gammainc(x/2, df/2))) -- computing dgi/dx
% 		directly can result in overflows in the intermediate stages
		val(val == 0) = nan;
		y = (df/2 - 1) * log(val/2) - val/2 - log(2) - gammaln(df/2);
		y(isnan(y)) = -inf;
		h = line(val, exp(y), 'linewidth', 2);
		figure(gcf)
		if nargout, cp = h; end
		return
	else
		error(sprintf('unknown command ''%s''', val))
	end
end

cp = gammainc(val/2, df/2);
