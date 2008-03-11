%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This script times a "ping pong" corner turn of
% a variety of sizes.
% To run, edit RUN.m, start Matlab and type:
%
%   RUN
%
% Output will be piped into to
%
%   MatMPI/CornerTurn.0.out
%   MatMPI/CornerTurn.0.mat
%   MatMPI/CornerTurn.1.out
%   MatMPI/CornerTurn.1.mat
%   ...
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Initialize pMatlab.
pMatlab_Init;
Ncpus = pMATLAB.comm_size;
my_rank = pMATLAB.my_rank;

% Set the number of message sizes.
n_message = 10;

% Set the number of trials at each messages size.
n_trial = 4;

if(Ncpus < 2)
 disp('ERROR: too few processors (need at least 2)');
 exit;
end

% Print rank.
disp(['my_rank: ',num2str(my_rank)]);

% Distribute processors and create maps.
n = [[0 (Ncpus/2-1)]; [(Ncpus/2) (Ncpus-1)]];
% Put A on first half of cpus.
mapA = map(       size(n(1,1):n(1,2)) , {}, n(1,1):n(1,2) );
% Put B on second half of cpus.
mapB = map(fliplr(size(n(2,1):n(2,2))), {}, n(2,1):n(2,2) );

% Create timing matrices.
start_time = zeros(n_trial,n_message);
end_time = start_time;

% Compute matrix sizes.
p = 1:n_message;
matrix_size = 2.^p;
message_size = matrix_size.*matrix_size;
byte_size = 8.*message_size;

% Get a zero clock.
zero_clock = clock;

% Loop over each message size.
for i_message = 1:n_message

  m = matrix_size(i_message);

  % Initialize matrices.
  A1 = rand(m,m, mapA);
  A2 = zeros(m,m, mapA);
  B1 = rand(m,m, mapB);
  B2 = zeros(m,m, mapB);

  for i_trial = 1:n_trial

    % Get start time for this message.
    start_time(i_trial,i_message) = etime(clock,zero_clock);

    % Send A -> B;
    B1(:,:) = A1;

    % Send B -> A;
    A2(:,:) = B2;

    % Get end time for the this message.
    end_time(i_trial,i_message) = etime(clock,zero_clock);

    total_time = end_time(i_trial,i_message) - start_time(i_trial,i_message);

  end
end

% Compute bandwidth.
total_time = end_time - start_time;
byte_size_matrix = repmat(byte_size,n_trial,1);
bandwidth = 2.*byte_size_matrix./total_time;

% Write data to a file.
outfile = ['CornerTurn.',num2str(my_rank),'.mat'];
save(outfile,'byte_size','start_time','end_time','total_time','byte_size_matrix','bandwidth');

% Finalize the pMATLAB program
% Clears global variables
disp('SUCCESS');

% Don't exit if we are the host.
% Finalize pMatlab.
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