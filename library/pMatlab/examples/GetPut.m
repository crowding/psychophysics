%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This script compares the time of global vs. local
% gets and put (on strictly local) data.  It illustrates
% a bug in the Matlab OO framework, which should be
% corrected in future releases of Matlab.
%
% To run, edit RUN.m, start Matlab and type:
%
%   RUN
%
% Output will be piped into to
%
%   MatMPI/GetPut.0.out
%   MatMPI/GetPut.1.out
%   ...
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Turn parallelism on or off.
PARALLEL = 1;  % Can be 1 or 0.  OK to change.

% Set the  problem dimensions.
NUM_CHANNELS = 32; % Elements. OK to change.
NUM_SAMPLES = 1024; % Samples per channel. OK to change. %1024

% Initialize pMatlab.
pMatlab_Init;
Ncpus = pMATLAB.comm_size;
my_rank = pMATLAB.my_rank;

% Create Maps.
mapX = 1;
if (PARALLEL)
  % Break up channels.
  mapX = map([Ncpus 1], {}, 0:Ncpus-1 );
end

tic;
% Allocate parallel data structures.
X = rand(NUM_SAMPLES,NUM_CHANNELS, mapX);
allocation_time = toc

% Get local data.
Xlocal = local(X);

% Get global indices.
[myI myJ] = global_ind(X);
 
% Time global get.
tic;
for i=1:NUM_SAMPLES
   r = X(i,:);
end
global_get_time1 = toc

% Time global get.
tic;
for i=1:length(myI)
   r = X(myI(i),:);
end
global_get_time2 = toc

% Time local get.
tic;
for i=1:length(myI)
   r = Xlocal(i,:);
end
local_get_time = toc


% Create some random data.
r = rand(1,NUM_CHANNELS);


% Time global put.
tic;
for i=1:NUM_SAMPLES
   X(i,:) = r;
end
global_put_time1 = toc

% Time global put.
tic;
for i=1:length(myI)
   X(myI(i),:) = r;
end
global_put_time2 = toc

% Time local get.
tic;
for i=1:length(myI)
   Xlocal(i,:) = r;
end
local_put_time = toc

% Finalize the pMATLAB program
disp('SUCCESS');
pMatlab_Finalize;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% pMatlab: Parallel Matlab Toolbox
% Software Engineer: Ms. Nadya Travinin (nt@ll.mit.edu)
% Architect:      Dr. Jeremy Kepner (kepner@ll.mit.edu)
% MIT Lincoln Laboratory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2005, Massachusetts Institute of Technology All rights 
% reserved.
% 
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are 
% met:
%      * Redistributions of source code must retain the above copyright 
%        notice, this list of conditions and the following disclaimer.
%      * Redistributions in binary form must reproduce the above copyright 
%        notice, this list of conditions and the following disclaimer in
%        the documentation and/or other materials provided with the
%        distribution.
%      * Neither the name of the Massachusetts Institute of Technology nor 
%        the names of its contributors may be used to endorse or promote 
%        products derived from this software without specific prior written 
%        permission.
% 
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
% IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
% THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
% PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
% CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
% EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
% PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
% PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
% LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
% NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
% SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.