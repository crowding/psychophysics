function varargout = psignifit(varargin)
% PSIGNIFIT       engine for PFIT
% 
%   [EST_P OBS_S SIM_P SIM_S LDOT] = PSIGNIFIT(DATA, PREFS) performs a
%   constrained maximum-likelihood fit on the psychophysical data
%   DATA, using a model described by the batch string PREFS. If PREFS
%   are set accordingly (containing a #RUNS field with a non-zero value)
%   then the given number of simulations will also be performed: simulated
%   data sets are generated either from the initial fit, or from a
%   distribution specified in PREFS.
% 
%   NB: Under MATLAB 5, you should not usually need to call PSIGNIFIT
%   directly. The function PFIT provides a much more convenient interface to
%   the engine, allowing results to be stored as structures.
% 
%   DATA must be specified as a three-column matrix, in one of the three
%   standard formats: "xyn", "xrn" and "xrw" (see PLOTPD.m)
%   
%   The PREFS string is a batch string (see batch_strings.m). It can be
%   generated on the MATLAB 5 command line using the command BATCH,
%   or can be converted from a MATLAB 5 struct using STRUCT2BATCH.
%   Alternatively, it may be read from a text file using the command
%   READTEXT. The options that can be specified in PREFS are described
%   in psych_options.m (type "help psych_options").
% 
%   The output matrices EST_P and SIM_P contain model parameters. Each row
%   is a set of parameters with columns in the order: alpha, beta, gamma,
%   lambda (see PSI). EST_P has a single row, giving the parameters from the
%   initial fit, if one was performed. SIM_P has one row of parameters per
%   simulated fit, if any were performed. Matrices in this format are
%   suitable as input argument for FINDTHRESHOLD, FINDSLOPE, PLOTPF or
%   CONFINT.
%   
%   The output matrices OBS_S and SIM_S contain statistics: the first column
%   is a deviance value, and the second is a correlation coefficient between
%   signed deviance residuals and expected values. The statistics in OBS_S
%   describe how well the original data are predicted by the fitted model
%   (or by the generating distribution, if simulations are performed and the
%   generating distribution has been specified separately). The statistics
%   is SIM_S describe how well each simulated data set (one per row) was
%   predicted by the generating distribution.
%   
%   The last argument, LDOT, contains information which is required in the
%   calculation of bias-corrected accelerated (BCa) confidence intervals.
%   It can be passed as an argument to CONFINT for checking the engine's BCa
%   calculations.
% 
%   
%   See also:
%     PFIT
%     BATCH, BATCH2STRUCT, STRUCT2BATCH
%     READTEXT
%     PLOTPD, PLOTPF
%     FINDTHRESHOLD, FINDSLOPE
%     CONFINT

% Part of the psignifit toolbox version 2.5.6 for MATLAB version 5 and up.
% Copyright (c) J.Hill 1999-2005.
% Please read the LICENSE and NO WARRANTY statement in psych_legal.m
% mailto:psignifit@bootstrap-software.org
% http://bootstrap-software.org/psignifit/

error('the PSIGNIFIT engine (mex-file) needs to be installed, or needs to be given a higher priority on the path than PSIGNIFIT.M')