% PSYCH_TOOL_DEMO        tutorial file: use of the PSIGNIFIT engine
% 
% Designed to work through and demonstrate the essential functions in a logical order.
% Open the script and execute it with command-E. Then read through the comments to see
% which functions do what, and look at the help comments in each of the relevant function
% files.

% Part of the psignifit toolbox version 2.5.6 for MATLAB version 5 and up.
% Copyright (c) J.Hill 1999-2005.
% Please read the LICENSE and NO WARRANTY statement in psych_legal.m
% mailto:psignifit@bootstrap-software.org
% http://bootstrap-software.org/psignifit/



% Read a sample data set from a text file in this directory, and plot the data.
dat = readdata('example_data.txt');
colordef white, figure
plotpd(dat)
hold on


% Make a batch string out of the preferences: 999 bootstrap replications
% assuming 2AFC design. All other options standard.
% Type "help psych_options" for a list of options that can be specified for
% psignifit.mex. Type "help batch_strings" for an explanation of the format.
shape = 'weibull';
prefs = batch('shape', shape, 'n_intervals', 2, 'runs', 999)
outputPrefs = batch('write_pa', 'pa', 'write_th', 'th');

% Fit the data, according to the preferences we specified (999 bootstraps).
% The specified output preferences will mean that two structures, called
% 'pa' (for parameters) and 'th' (for thresholds) are created.
psignifit(dat, [prefs outputPrefs]);

% Plot the fit to the original data
plotpf(shape, pa.est);

% Draw confidence intervals using the 'lims' field of th, which
% contains bias-corrected accelerated confidence limits.
drawHeights = psi(shape, pa.est, th.est);
line(th.lims, ones(size(th.lims,1), 1) * drawHeights, 'color', [0 0 1])
hold off

% wait for key press
figure(gcf), xlabel('press any key....', 'fontsize', 24), drawnow, pause, xlabel('')

% Plot 200 of the bootstrap fits...
hold on
plotpf(shape, pa.sim(1:min(200, size(pa.sim, 1)), :))
% ...and superimpose what we had showing before
col = [0.7 0.9 0.9];
plotpd(dat, 'color', col)
plotpf(shape, pa.est, 'linewidth', 3, 'color', col)
line(th.lims, ones(size(th.lims,1), 1) * drawHeights, 'linewidth', 4, 'color', col)
hold off

