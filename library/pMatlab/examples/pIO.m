%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This script creates a distributed matrix. Writes it
% out in a scalable way and the reads it back in.
%
% To run, edit RUN.m, start Matlab and type:
%
%   RUN
%
% Output will be piped into to
%
%   MatMPI/pIO.0.out
%   MatMPI/pIO.1.out
%   ...
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Set the  problem dimensions.
NUM_CHANNELS = 8; % Elements. OK to change.
NUM_SAMPLES = 2^18; % Samples per channel. OK to change. %1024
SHOWME = 0;  % Display flag. OK to change.
FILENAME = './pIO_test_data';

% Turn parallelism on or off.
PARALLEL = 1;  % Can be 1 or 0.  OK to change.

% Initialize pMatlab.
pMatlab_Init;
Ncpus = pMATLAB.comm_size;
my_rank = pMATLAB.my_rank;

% Create Maps.
mapX = 1;
if (PARALLEL)
  % Break up channels.
  mapX = map([1 Ncpus], {}, 0:Ncpus-1 );
end

tic;
% Allocate parallel data structures.
Xrand = complex(rand(NUM_SAMPLES,NUM_CHANNELS, mapX),rand(NUM_SAMPLES,NUM_CHANNELS, mapX));
Yrand = complex(zeros(NUM_SAMPLES,NUM_CHANNELS, mapX));
allocation_time = toc

% Save each channel as a seperate file.
tic;
pIO_Write(Xrand,FILENAME);
save_time = toc

% Read back into array.
Yrand = pIO_Read(Yrand,FILENAME);

load_time = toc

% Compare results.
max_difference = max(max(abs( local(Xrand) - local(Yrand) )));

if (max_difference > 0)
  disp('ERROR');
  max_difference
else
  disp('SUCCESS');
end

% Finalize the pMatlab program
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