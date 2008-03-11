%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This script creats a very simple radar clutter simulation.
% and processes it in parallel.
%
% To run, edit RUN.m, start Matlab and type:
%
%   RUN
%
% Output will be piped into to
%
%   MatMPI/ClutterSim.0.out
%   MatMPI/ClutterSim.1.out
%   ...
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ClutterSim Demo design: Nick Pulsone / MIT Lincoln Lab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Turn parallelism on or off.
PARALLEL = 1;  % Can be 1 or 0.  OK to change.

% Initialize pMatlab.
pMatlab_Init;
Ncpus = pMATLAB.comm_size;
my_rank = pMATLAB.my_rank;

% Set the  problem dimensions.
Nchannels = 10;
Nranges = 1000;
Npulses = 100;

% Create map.
mapX = 1;
if (PARALLEL)
  % Break up in range.
  mapX = map([Ncpus 1], {}, 0:Ncpus-1 );
end

% Allocate data structures.
Xrand = complex( rand(Nranges,Nchannels.*Npulses,mapX), ...
                 rand(Nranges,Nchannels.*Npulses,mapX));
X =     complex(zeros(Nranges,Nchannels.*Npulses,mapX));

% Create base covariance matrix.
R = ClutterSim_CovMat(Nchannels,Npulses);

% Cholesky factor.
cholR = chol(R);


% Start clock.
tic;

% Apply to data.  Does implicit parallel matrix multiply.
% X(:,:) = Xrand*cholR;

% Alternate form, explicitly local.
X = put_local(X, local(Xrand)*cholR );

matmul_time = toc

disp('SUCCESS');

% Don't exit if we are the host.
% Finalize pMatlab.
pMatlab_Finalize;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% pMatlab: Parallel Matlab Toolbox
% Software Engineer: Ms. Nadya Travinin (nt@ll.mit.edu)
% Architect: Dr. Jeremy Kepner (kepner@ll.mit.edu)   
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