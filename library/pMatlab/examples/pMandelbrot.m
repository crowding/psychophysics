%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This script implements a Mandelbrot calculation
% across multiple processors.
% To run, start Matlab and type:
%
%   eval( MPI_Run('pMandelbrot',2,{}) );
%
% Or, to run a different machine type:
%
%   eval( MPI_Run('pMandelbrot',2,{'machine1' 'machine2'}) );
%
% Output will be piped into to
%
%   MatMPI/blurimage.0.out
%   MatMPI/blurimage.1.out
%   ...
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Set control flags.
PARALLEL = 1;

% Initialize pMatlab..
pMatlab_Init;
Ncpus = pMATLAB.comm_size;
my_rank = pMATLAB.my_rank;

% Print rank.
disp(['my_rank: ',num2str(my_rank)]);


% Create maps
mapW = 1;
mapW0 = 1;
if (PARALLEL)
  mapW = map([Ncpus 1],{},[0:Ncpus-1]);
  mapW0 = map([1 1],{},[0]);
end

% Set number of iterations.
col=20;
  
% Set mesh size.
m=1000;

% Create input and output arrays.
W = zeros(m,m,mapW);
W0 = zeros(m,m,mapW0);

% Get local indices.
[myI myJ] = global_ind(W);

% Create local x and y coordinates.
[x y] = meshgrid(myJ./(m/2) -1.6, myI./(m/2) -1 );

% Turn into complex.
c = complex(x,y);

% Set initial value.
z = c;

tic;
% Compute Mandelbrot set.
for k=1:col;

  z = z.^2 + c;
  W_local = exp(-abs(z));

end

% Put result back into distributed array.
W = put_local(W, W_local);

Mandelbrot_time = toc

% Copy W back to leader.
W0(:,:) = W;

% Get local part.
W0_local = local(W0);


% Don't exit if we are the host.
disp('SUCCESS');
if (PARALLEL)
  % Finalize Matlab MPI.
  pMatlab_Finalize;
end

% Display on leader.
colormap copper(256);
pcolor(W0_local);
shading flat;
axis('square','equal','off');

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