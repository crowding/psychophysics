% Psychometric function fitting, bootstrap confidence intervals, statistics
% 
% Main functions
% 
%   PFIT           -  fit, bootstrap, sensitivity analysis & stats.
%   PSYCHOSTATS    -  Monte Carlo goodness-of-fit tests
%   PSYCH_GLOSS    -  glossary of terms, struct fieldnames and common
%                     variable names 
%   PSYCH_OPTIONS  -  documentation on the available fitting options
% 
% Graphics and plotting
% 
%   KEY             -  similar to LEGEND: add a key to a plot
%   PLOTPD          -  plots psychophysical data
%   PLOTPF          -  plots a fitted psychometric curve
%   PSYCHERRBAR     -  plot horizontal or vertical error bars
% 
% More detail (functions used by PFIT)
% 
%   PSYCH_TOOL_DEMO -  an annotated run through the essential calls
% 
%   CONFINT         -  confidence intervals derived from bootstrap results
%   CPE             -  cumulative probability estimate
%   FINDSLOPE       -  compute slopes and thresholds of F or psi
%   FINDTHRESHOLD   -  compute thresholds of F or psi
%   PSI             -  predicts psychophysical performance from parameters
%   PSYCHF          -  shape of function F underlying PSI
%   PSIGNIFIT       -  main engine: performing fit and/or simulations
%   PSYCHREPORT     -  text reporting of PFIT results
%   READDATA        -  read a MATLAB array from a text file 
% 
% Specifying options: working with batch strings
% 
%   BATCH           -  build or edit a batch string
%   BATCH2STRUCT    -  convert from a batch string to a MATLAB 5 struct
%   STRUCT2BATCH    -  convert from a MATLAB 5 struct to a batch string
%   BATCH_STRINGS   -  explanation of the batch string format
% 
%   READTEXT        -  read a text file in as a MATLAB string
%   WRITETEXT       -  write out a MATLAB string to a text file
% 
% 

% Part of the psignifit toolbox version 2.5.6 for MATLAB version 5 and up.
% Copyright (c) J.Hill 1999-2005.
% Please read the LICENSE and NO WARRANTY statement in psych_legal.m
% mailto:psignifit@bootstrap-software.org
% http://bootstrap-software.org/psignifit/
