%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This script implements a simple parallel Streams
% benchmark.  It times:
%   COPY          A(i) = B(i)
%   SCALE         A(i) = q*B(i)
%   ADD           A(i) = q*B(i)
%   TRIAD         A(i) = B(i) + q*C(i)
%
% For parallel systems, we impose the constraint that
% the size of A, B, and C should take
% up at least half of the total system memory.
%
% To run, edit RUN.m, start Matlab and type:
%
%   RUN
%
% Output will be piped into to
%
%   MatMPI/pStreams.0.out
%   MatMPI/pStreams.1.out
%   ...
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
% Turn parallelism on or off.
PARALLEL = 1;  % Can be 1 or 0.  OK to change.

% Initialize pMatlab..
Ncpus = 1;
if (PARALLEL)
  pMatlab_Init;
  Ncpus = pMATLAB.comm_size;
  my_rank = pMATLAB.my_rank;
  % Print rank.
  disp(['my_rank: ',num2str(my_rank)]);
end

% Scale data size by number of cpus size.
N = 2.^(20+1)*Ncpus;
N = 2.^(15+1)*Ncpus;

% Create maps
ABCmap = 1;
if (PARALLEL)
  % Create map.
  ABCmap = map([1 Ncpus],{},[0:Ncpus-1]);
end

% Allocate data structure.
A = zeros(1,N,ABCmap);
B = rand(1,N,ABCmap);
C = rand(1,N,ABCmap);

% Pick a constant.
q = 3.14;

% Set the number of times to loop..
n_trial = 2;

% Compute number of operations.
total_ops = 2.*n_trial*N;



% COPY
tic;
% Loop over each trial.
for i_trial = 1:n_trial

  % Pure local version.
  % Alocal = local(B);
  % A = put_local(A,Alocal);

  % Pure global version.
  A(:,:) = B;

end
copy_time = toc;
copy_gigaops = total_ops / copy_time / 1.e9;
disp(['Copy GigaOps: ',num2str(copy_gigaops)]);


% SCALE
tic;
% Loop over each trial.
for i_trial = 1:n_trial

  % Pure local version.
  % Alocal = q*local(B);
  % A = put_local(A,Alocal);

  % Pure global version.
  A(:,:) = q*B;

end
scale_time = toc;
scale_gigaops = total_ops / scale_time / 1.e9;
disp(['Scale GigaOps: ',num2str(scale_gigaops)]);


% ADD
tic;
% Loop over each trial.
for i_trial = 1:n_trial

  % Pure local version.
  % Alocal = local(B) + local(C);
  % A = put_local(A,Alocal);

  % Pure global version.
  A(:,:) = B + C;

end
add_time = toc;
add_gigaops = total_ops / add_time / 1.e9;
disp(['Add GigaOps: ',num2str(add_gigaops)]);


% TRIAD
tic;
% Loop over each trial.
for i_trial = 1:n_trial

  % Pure local version.
  % Alocal = local(B) + q*local(C);
  % A = put_local(A,Alocal);

  % Pure global version.
  A(:,:) = B + q*C;

end
triad_time = toc;
triad_gigaops = total_ops / triad_time / 1.e9;
disp(['Triad GigaOps: ',num2str(triad_gigaops)]);



% Don't exist if we are the host.
disp('SUCCESS');
if (PARALLEL)
  % Finalize Matlab MPI.
  pMatlab_Finalize;
end

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

