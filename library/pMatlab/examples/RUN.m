% RUN is a generic script for running pMatlab scripts.

% Define number of processors to use.
% All the examples should work with 1, 2, 4 and 8 CPUs.
Ncpus = 4;

% Uncomment the name of the script you want to run.
mFile = 'fftTest';  % Trivially parallel fft.
% mFile = 'pStreams';  % A(i) = B(i), q*B(i), B(i)+C(i), B(i) + q*C(i)
% mFile = 'CornerTurn';  % Basic redistribution pipeline parallel processing.
% mFile = 'pIO'; % Scalable parallel file I/O)
% mFile = 'ClutterSim'; % Basic data parallel processing.
% mFile = 'GeneratorProcessor'; % Multi-stage pipeline parallel processing.
% mFile = 'pBlurimage'; % Overlap, local arrays and global indices.
% mFile = 'GetPut'; % Performance of different Get/Put styles.

% Define cpus.
% Empty implies run on host.
cpus = {};

% setting cpus = 'grid' means run on LLgrid
% cpus = 'grid';

% Specify machine names to run remotely.
% cpus = {'n1' 'n2'};

% Add cross-mounted directories for better performance.
% cpus = {'n1:/scratch/n1/username' 'n2:/scratch/n2/username'};
%
% Full syntax is:
% cpus = {'machine1[&]:[pc|unix]:[dir1]' 'machine2:[pc|unix]:[dir2]' ...}.

% Abort left over jobs.
MPI_Abort;
pause(2.0);

% Delete left over MPI directory
MatMPI_Delete_all;
pause(2.0);

% Define global variables
global pMATLAB;


% Run the script.
['Running: ' mFile ' on ' num2str(Ncpus) ' cpus']
eval(MPI_Run(mFile, Ncpus, cpus));

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