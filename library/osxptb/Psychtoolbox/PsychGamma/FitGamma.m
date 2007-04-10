function [fit_out,x,fitComment] = ...
  FitGamma(values_in,measurements,values_out,fitType)
% [fit_out,x,fitComment] = ...
%   FitGamma(values_in,measurements,values_out,[fitType])
% 
% Fit a gamma function.  This essentially a driver function.
% It has two main purposes.
%
% First it tries several different
% underlying parametric forms for the fit and chooses the best
% for a particular data set.
%
% Second, it does the bookkeeping for fitting each column of
% input measurements.  (Each of the underlying fit functions expects
% only vector input.)
%
% To a large extent, the interface to the underlying fit functions
% (e.g. FitGammaPow, FitGammaSig, ...) is uniform.  However, this routine
% does have to know a little bit about initial value dimension and choice.
% We have tried to localize this information in the initialization routines
% (e.g. InitialXPow, InitialXSig, ...) as much as possible, but some
% caution is advised.
%
% Optional argument fitType allows you to force the return of a particular
% paramtetric form.  Currently:
%   fitType == 1:  Power function
%   fitType == 2:  Extended power function
%   fitType == 3:  Sigmoid
%   fitType == 4:  Weibull
%   fitType == 5:  Modified polynomial
%   fitType == 6:  Linear interpolation
%   fitType == 7:  Cubic spline
%
% All fit types are in a form such that the fit is forced through the
% origin for 0 input.  This is because our convention is that gamma
% correction happens after subtraction of the ambient light.
%
% NOTE: FitGammaPow (and perhaps other subroutines) uses CONSTR, which is part of the 
% Mathworks Optimization Toolbox.
% 
% Also see FitGammaDemo.

% 10/3/93   dhb		Removed polynomial fit from list tried with fitType == 0.
% 					Added Weibull function fit
% 3/15/94   dhb, jms Added linear interpolation.
% 7/18/94   dhb		Added cubic spline interpolation.
% 8/7/00    dhb     Fix bug.  Spline was calling linear interpolation.  Thanks to
%                   Chien-Chung Chen for notifying us of this bug.
% 11/14/06 dhb      Modify how default type is set.  Handle passed empty matrix.

% Get sizes
[null,nDevices] = size(measurements);
[nOut,null] = size(values_out);

% Set up number of fit types
nFitTypes = 5;
error = zeros(nFitTypes,nDevices);

% Handle force fittting
if (nargin < 4 || isempty(fitType))
  fitType = 0;
end

% Fit with simple power function through origin
if (fitType == 0 | fitType == 1 | fitType == 2)
  disp('Fitting with simple power function');
  fit_out1 = zeros(nOut,nDevices);
  [nParams,null] = size(InitialXPow);
  x1 = zeros(nParams,nDevices);
  for i = 1:nDevices
    x0 = InitialXPow;
    [fit_out1(:,i),x1(:,i),error(1,i)] = ...
      FitGammaPow(values_in,measurements(:,i),values_out,x0);
  end
  disp(sprintf('Simple power function fit, RMSE: %g',mean(error(1,i))));
end

% Fit with extended power function.  Use power function
% fit to drive parameters.  InitialXExtP can take a two
% vector as input.  This defines the parameters of a good fitting
% simple power function.
if (fitType == 0 | fitType == 2)
  disp('Fitting with extended power function');
  fit_out2 = zeros(nOut,nDevices);
  [nParams,null] = size(InitialXExtP);
  x2 = zeros(nParams,nDevices);
  for i = 1:nDevices
    x0 = InitialXExtP(x1(:,i));
    [fit_out2(:,i),x2(:,i),error(2,i)] = ...
      FitGammaExtP(values_in,measurements(:,i),values_out,x0);
  end
  disp(sprintf('Extended power function fit, RMSE: %g',mean(error(2,i))));
end

% Fit with a sigmoidal shape.  This works well for
% the dimmer packs controlling lights.  InitialXSig can take
% a two vector as input.  This defines roughly the input for
% half maximum and the maximum output value.
if (fitType == 0 | fitType == 3)
  disp('Fitting with sigmoidal function');
  fit_out3 = zeros(nOut,nDevices);
  [nParams,null] = size(InitialXSig);
  x3 = zeros(nParams,nDevices);
  for i = 1:nDevices
    maxVals = max(values_in);
    maxMeas = max(measurements(:,i));
    x0 = InitialXSig([maxVals/2]');
    [fit_out3(:,i),x3(:,i),error(3,i)] = ...
      FitGammaSig(values_in,measurements(:,i),values_out,x0);
  end
  disp(sprintf('Sigmoidal fit, RMSE: %g',mean(error(3,i))));
end

% Fit with Weibull
if (fitType == 0 | fitType == 4)
  disp('Fitting with Weibull function');
  fit_out4 = zeros(nOut,nDevices);
  [nParams,null] = size(InitialXWeib(values_in,measurements(:,1)));
  x4 = zeros(nParams,nDevices);
  for i = 1:nDevices
    x0 = InitialXWeib(values_in,measurements(:,i));
    [fit_out4(:,i),x4(:,i),error(4,i)] = ...
      FitGammaWeib(values_in,measurements(:,i),values_out,x0);
  end
  disp(sprintf('Weibull function fit, RMSE: %g',mean(error(4,i))));
end

% Fit with polynomial.  InitalXPoly is used mostly for consistency
% with other calling forms, since FitGammaPoly computes an analytic
% fit to start the search.  But it serves to implicitly defines the
% order of the polynomial.
if (fitType == 0 | fitType == 5)
  disp('Fitting with polynomial');
  fit_out5 = zeros(nOut,nDevices);
  [order5,null] = size(InitialXPoly);
  x5 = zeros(order5,nDevices);
  for i = 1:nDevices
    [fit_out5(:,i),x5(:,i),error(5,i)] = ...
       FitGammaPoly(values_in,measurements(:,i),values_out);
  end
  disp(sprintf('Polynomial fit, order %g, RMSE: %g',order5,mean(error(5,i))));
end

% Linear interpolation.  Error and x are bogus here, but
% we fill them in to keep the accountants upstream happy.
if (fitType == 6)
	disp('Fitting with linear interpolation');
  fit_out6 = zeros(nOut,nDevices);
  for i = 1:nDevices
    [fit_out6(:,i)] = ...
       FitGammaLin(values_in,measurements(:,i),values_out);
  end
	x6 = [];
	error6 = zeros(1,nDevices);
end

% Cubic spline.  Error and x are bogus here, but
% we fill them in to keep the accountants upstream happy.
if (fitType == 7)
	disp('Fitting with cubic spline');
  fit_out7 = zeros(nOut,nDevices);
  for i = 1:nDevices
    [fit_out7(:,i)] = ...
       FitGammaSpline(values_in,measurements(:,i),values_out);
  end
	x7 = [];
	error7 = zeros(1,nDevices);
end

% If we are not forcing a fit type, find best fit.
% Don't check linear interpolation, as it has zero error always.
% Currently we take the minimum mean error over all devices.
% In principle, could use best fit type for each device.  But
% that would make the interface tricky.
if (fitType == 0)
  meanErr = mean(error');
  [minErr,bestFit] = min(meanErr);
  fitType = bestFit;
end

if (fitType == 1)
  fit_out = fit_out1;
  x = x1;
  fitComment = (sprintf('Simple power function fit, RMSE: %g',...
    mean(error(1,i))));
elseif (fitType == 2)
  fit_out = fit_out2;
  x = x2;
  fitComment = (sprintf('Extended power function fit, RMSE: %g',...
    mean(error(2,i))));
elseif (fitType == 3)
  fit_out = fit_out3;
  x = x3;
  fitComment = (sprintf('Sigmoidal fit, RMSE: %g',...
    mean(error(3,i))));
elseif (fitType == 4)
  fit_out = fit_out4;
  x = x4;
  fitComment = (sprintf('Weibull fit, RMSE: %g',...
    mean(error(4,i))));
elseif (fitType == 5)
  fit_out = fit_out5;
  x = x5;
  fitComment = (sprintf('Polynomial fit, RMSE: %g',...
    mean(error(5,i))));
elseif (fitType == 6)
  fit_out = fit_out6;
  x = x6;
  fitComment = (sprintf('Linear interpolation fit'));
elseif (fitType == 7)
  fit_out = fit_out7;
  x = x7;
  fitComment = (sprintf('Cubic spline fit'));
end

% Check that fit is non-decreasing
if (CheckMonotonic(fit_out) == 0)
  disp('Warning, fit is not non-decreasing');
end


