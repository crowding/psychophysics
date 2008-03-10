
% This is the file to execute to run this parallel Matlab example.
% The following constants are defined here:
%   no_lines, fname, fs.
% This file defines a parallel function definition, sets up the phantom data, 
% starts the simulation and presents the result.
%
% This is done with using the following files: 
%  cyst_pht, probe_init.m, create_rf.  
%
%

fs = 100e6;                %  Sampling frequency [Hz]
image_width=40/1000;       % Size of image sector
no_lines = 128;             % How many RF lines to be created.
fname = 'rf_env/rf_ln';  % The path and files where the envelope data will be 
                           % stored. There will be no_lines files, and they'll 
                           % each have n.mat added at the end, where n is the line. 
no_scatterers = 100000;      % how many scatterers there will be in the phantom
pht_fname= 'pht_data.mat'; % name of the file where the phantom data will be stored.


% Initialise the parallel function definition
% -------------------------------------------

f = pmfun;
f = addcominput(f,'phantom_positions','LOAD');
f = addcominput(f,'phantom_amplitudes','LOAD',1);
f = addcominput(f,'no_lines','INPUT');
f = addcominput(f,'fs','INPUT');

f.prefun =['field2;probe_init'];
f.postfun='xdc_free(xmit_aperture);xdc_free(receive_aperture);field_end';

f.expr= 'create_rf;rf_env=abs(hilbert([zeros(round(tstart*fs),1); rf_data]));';

%input: x. outputs: rf_env 
f = addspecinput(f,'x','USERDATA');
f = addoutput(f,'rf_env','SAVEFILE');

f.blocks=pmblock(no_lines);
fnames = cell(no_lines,1);
x = zeros(no_lines,1);
d_x=image_width/no_lines;       %  Increment for image
for n = 1:no_lines,
  x(n) = -image_width/2 +(n-1)*d_x;
  fnames{n} = [fname sprintf('%d',n) '.mat'];
end
f.blocks = setattr(f.blocks,'dstfile',1,fnames);
f.blocks = setattr(f.blocks,'userdata',1,x);



% Set up the phantom data and save it to pht_fname
% ------------------------------------------------

[phantom_positions, phantom_amplitudes] = cyst_pht(no_scatterers);
save(pht_fname,'phantom_positions','phantom_amplitudes');


% make the output directory if it didn't already exist:
!mkdir rf_env

% Start the dispatch
% ------------------

cnf.gui = 0
cnf.saveinterv = inf;
cnf.statefile = 'pmstate';
cnf.debug = 1;
cnf.logfile = 'stdout';

err=dispatch(f,0,{pht_fname,no_lines,fs},{},[],cnf)

pmclose

pmake_img





