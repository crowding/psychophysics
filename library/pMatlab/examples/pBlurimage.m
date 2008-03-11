%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This script implements a basic image convolution
% across multiple processors.  It illustrates how to
% use overlaping boundaries and how to validate results
% with an equivale serial calculation.
%
% To run, edit RUN.m, start Matlab and type:
%
%   RUN
%
% Output will be piped into to
%
%   MatMPI/pBlurimage.0.out
%   MatMPI/pBlurimage.1.out
%   ...
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Turn parallelism on or off.
PARALLEL = 1;  % Can be 1 or 0.  OK to change.

% Check answer with an identical serial calculation.
CHECK = 0;  % Can be 1 or 0.  OK to change.

% Initialize pMatlab..
pMatlab_Init;
Ncpus = pMATLAB.comm_size;
my_rank = pMATLAB.my_rank;

% Scale image by number of cpus size (use powers of 2).
n_image_x = 2.^(10+1)*Ncpus;
n_image_y = 2.^10;

% Number of points to put in each sub-image.
n_point = 100;

% Set filter size (use powers of 2).
n_filter_x = 2.^5;
n_filter_y = 2.^5;

% Create maps
mapImOv = 1;
if (PARALLEL)
  % Create map with 1D of overlap.
  mapImOv = map([Ncpus 1],{},[0:Ncpus-1],[n_filter_x 0]);
  % Create map with 2D of overlap.
  % mapImOv = map([Ncpus/2 2],{},[0:Ncpus-1],[n_filter_x n_filter_y]);
end

% Set the number of times to filter.
n_trial = 2;

% Compute number of operations.
total_ops = 2.*n_trial*n_filter_x*n_filter_y*n_image_x*n_image_y;

% Print rank.
disp(['my_rank: ',num2str(my_rank)]);

% Create timing matrices.
start_time = zeros(n_trial);
end_time = start_time;

% Get a zero clock.
zero_clock = clock;

% Create starting image and working images..
if (CHECK)   im = zeros(n_image_x,n_image_y); end

imOv = zeros(n_image_x,n_image_y,mapImOv);

% Get local indices.
[myI myJ] = global_ind(imOv);

% Assign values to image.
imOv_local = local(imOv);
imOv_local = (myI.' * ones(1,length(myJ))) + (ones(1,length(myI)).' * myJ);
imOv = put_local(imOv,imOv_local);

if (CHECK)
  im = ((1:n_image_x).' * ones(1,n_image_y)) + (ones(1,n_image_x).' * (1:n_image_y));
end

% Create kernel.
%x_shape = sin(pi.*(0:(n_filter_x-1))./(n_filter_x-1)).^2;
%y_shape = sin(pi.*(0:(n_filter_y-1))./(n_filter_y-1)).^2;
%kernel = (x_shape.')*y_shape;
kernel = ones(n_filter_x,n_filter_y)./(n_filter_x*n_filter_y);

% Copy boundary conditions.  Actually being used here as
% a barrier synchronization.
imOv = synch(imOv);

% Set start time.
start_time = etime(clock,zero_clock);

% Loop over each trial.
for i_trial = 1:n_trial

  % Get local data.
  imOv_local = local(imOv);
  % Perform covolution.
  imOv_local(1:end-n_filter_x+1,1:end-n_filter_y+1) = conv2(imOv_local,kernel,'valid');
  % Put local back in global.
  imOv = put_local(imOv,imOv_local);
  % Coping overlaping boundaries.
  imOv = synch(imOv);

  if (CHECK)
    im(1:end-n_filter_x+1,1:end-n_filter_y+1) = conv2(im,kernel,'valid');
  end

end

% Compare results.
if (CHECK)
  max_difference = max(max(abs(local(imOv) - im(myI,myJ))))
  % imagesc(local(imOv) - im(myI,myJ))
end

% Get end time for the this message.
end_time = etime(clock,zero_clock);

% Print the results.
total_time = end_time - start_time

% Print compute performance.
total_ops;
gigaflops = total_ops / total_time / 1.e9;
disp(['GigaFlops: ',num2str(gigaflops)]);

% Don't exist if we are the host.
disp('SUCCESS');
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

