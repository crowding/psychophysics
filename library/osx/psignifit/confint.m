function [out1, out2] = confint(d, conf, trueD, lff, ldot, names, xtra)
% CONFINT     confidence intervals based on bootstrap distributions
% 
%     LIMS = CONFINT(METHOD, D, CONF, TRUE_D, LFF, LDOT) returns confidence
%     intervals based on quantiles of the bootstrap distributions supplied in
%     the columns of matrix D. The vector CONF determines the cumulative
%     probabilities of the quantiles that are returned: thus
%         CONFINT(D, [0.16 0.84], ...)
%     might be used to estimate the mean +/- one standard deviation if the
%     variables in the columns of D were gaussian.
%     
%     CONFINT has two modes: confidence interval limits can be found using
%     the percentile method, or using an adjusted-percentile technique called
%     bias-corrected accelerated method (BCa). The coverage of BCa confidence
%     intervals can be shown to converge faster than that of ordinary
%     percentile limits. Thus, BCa is the preferred method and the default
%     mode of operation for CONFINT: the argument METHOD would normally be
%     omitted, in which case the call is equivalent to:
%         CONFINT('BCa', D, .....)
% 
%     LIMS has one column per column of D: limits in different columns refer
%     to different variables. Each row corresponds to a different value of
%     CONF.
%         
%     For the percentile method, arguments TRUE_D, LFF and LDOT may be omitted.
%     They are used only in the BCa method, and their meaning is as follows:
%         TRUE_D:     the true underlying value (or the maximum-likelihood
%                     estimate) of each of the random variables in the columns
%                     of D. TRUE_D must therefore have one element per column
%                     of D.
%         LFF:        The least-favourable direction in parameter space for
%                     inference about each of the variables. LFF must have
%                     a column for each variable, and four rows indicating the
%                     components of the least-favourable direction in the
%                     dimensions of the four parameters. A least-favourable
%                     direction vector should be calculated for each parameter,
%                     threshold or slope estimate - see Davison & Hinkley, 
%                     1997, Bootstrap methods and their application, Cambridge
%                     University Press, p206-7 and p249.
%         LDOT:       The derivative of log-likelihood, with respect to
%                     each of the parameters, evaluated at the MLE, for each
%                     of the bootstrap data sets. Thus LDOT should have the
%                     same number of rows as D, and four columns (one for each
%                     parameter). LDOT is output by the PSIGNIFIT engine,
%                     although in the current version, it is always returned
%                     as empty.
%                     
%         See also PSIGNIFIT, QUANTILE, CPE.

% Part of the psignifit toolbox version 2.5.6 for MATLAB version 5 and up.
% Copyright (c) J.Hill 1999-2005.
% Please read the LICENSE and NO WARRANTY statement in psych_legal.m
% mailto:psignifit@bootstrap-software.org
% http://bootstrap-software.org/psignifit/
		
if nargin < 3, trueD = []; end
if nargin < 4, lff = []; end
if nargin < 5, ldot = []; end
if nargin < 6, names = []; end
if nargin < 7, xtra = []; end

if isstr(d)
	opt = d; d = conf; conf = trueD; trueD = lff; lff = ldot; ldot = names; names = xtra; % all change, please
else
	opt = 'both';
end
if isempty(d) | isempty(conf), out1 = []; out2 = []; return, end

matchOpt = strmatch(lower(opt), {'both', 'bca', 'percentiles'});
if length(matchOpt) ~= 1, matchOpt = 0; end
switch matchOpt
	case 1, bcaOut = 1; perOut = 1;
	case 2, bcaOut = 1; perOut = 0;
	case 3, bcaOut = 0; perOut = 1;
	otherwise, error(sprintf('unknown command option ''%s''', opt))
end

if isempty(d) | isempty(conf), out1 = []; out2 = []; return, end
if bcaOut
	if isempty(trueD) | isempty(lff) | isempty(ldot)
		error('for BCa output, arguments TRUE_D, LFF and LDOT must be supplied')
	end
	if size(trueD,1) ~= 1 | size(trueD,2) ~= size(d, 2), error('argument TRUE_D must have 1 row, and the same number of columns as D'), end 
	if size(lff,2) ~= size(d, 2)
		error('argument LFF must the same number of columns as D')
	end 
	if size(lff,1) ~= size(ldot, 2),
		error('number of rows in LFF must match the number of columns in LDOT (= the number of parameters)')
	end
	if size(ldot, 1) ~= size(d, 1)
		error('argument LDOT must the same number of rows as D')
	end
	bias = cpe(trueD, d);
	ldot = ldot * lff;
end

conf = conf(:);
bca = NaN + zeros(length(conf), size(d, 2));
per = NaN + zeros(length(conf), size(d, 2));

if ~isempty(names)
	if isstr(names) & size(names, 1) == 1 & ~isempty(names), names = {names}; end
	if ~iscellstr(names), error('''names'' should be a cell array of strings'), end
	names = names(:);
	if length(names) ~= 1 & length(names) ~= size(d,2), error('if descriptions are supplied there should be one string per column of D'), end
end
if length(names) == 1, description = sprintf('%s distribution matrix', names{1});
elseif ~isempty(names), description = sprintf('{%s, %s, ...} distribution matrix', names{1}, names{2});
else description = 'distribution matrix';
end

ans = find(all(isnan(d), 2));
if ~isempty(ans), warning(sprintf('removed %d rows of NaNs from the %s', length(ans), description)), end
d(ans, :) = [];

for i = 1:size(d, 2)
	if length(names) == size(d, 2)
		description = sprintf('%s distribution', names{i});
	elseif length(names) == 1
		description = sprintf('%s distribution (column %d)', names{1}, i);
	else
		description = sprintf('distribution of values in column %d', i);
	end
	dist = d(:,i);
	remove = find(isnan(dist));
	if ~isempty(remove), warning(sprintf('disregarding %d NaNs from the %s', length(remove), description)), end
	dist(remove) = [];
	dist = sort(dist);
	if perOut & ~isempty(dist), per(:, i) = quantile(dist, conf, 'already sorted'); end
	if bcaOut & ~isempty(dist)
		stdv = std(ldot(:, i));
		if bias(i) <= 0 | bias(i) >= 1
			warning(sprintf('could not calculate BCa confidence levels for the bootstrap %s', description))
		else	% see Efron & Tibshirani, p185, or Davison & Hinkley p203ff
			w = inversecumulativegaussian(bias(i), 0, 1);
			if stdv == 0
				a = 0;
			else
				a = mean(ldot(:, i).^3) / (6 * stdv .^ 3);
			end
			z = inversecumulativegaussian(conf, 0, 1);
			confBCa = cumulativegaussian(w + (w + z) ./ (1 - a * (w + z)), 0, 1);
			[warn1 warn2] = warning; warning off
			bca(:, i) = quantile(dist, confBCa, 'already sorted');
			warning(warn1); warning(warn2);
		end
	end
end
out1 = []; out2 = [];
if bcaOut
	out1 = bca; out2 = per;
elseif perOut
	out1 = per; out2 = bca;
end

