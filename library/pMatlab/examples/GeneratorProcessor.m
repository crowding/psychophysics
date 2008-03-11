%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GeneratorProcessor is an example of a multi-stage
% parallel pipeline.  The first have generates synthetic
% data and then passes the data into to the second half
% which processes the data.
%%
% To run, edit RUN.m, start Matlab and type:
%
%   RUN
%
% Output will be piped into to
%
%   MatMPI/GeneratorProcessor.0.out
%   MatMPI/GeneratorProcessor.1.out
%   ...
%
% Edit GeneratorProcessor_Params to change behavior.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        

% pMatlab Initialization
pMatlab_Init;
tic;

% Set Parameters.
GeneratorProcessor_Params;

% Set number of timing stages.
t_stages = zeros(NUM_TIME,7);

% Create parallel maps.
GeneratorProcessor_Maps;

% Allocate (parallel) data structures.
Xrand = 0.01*complex(rand(NUM_SAMPLES,NUM_BEAMS, map0),rand(NUM_SAMPLES,NUM_BEAMS, map0));
X0 = complex(zeros(NUM_SAMPLES,NUM_BEAMS, map0));
X1 = complex(zeros(NUM_SAMPLES,NUM_BEAMS, map1));
X2 = complex(zeros(NUM_SAMPLES,NUM_CHANNELS, map2));
X3 = complex(zeros(NUM_SAMPLES,NUM_CHANNELS, map3));
X4 = complex(zeros(NUM_SAMPLES,NUM_BEAMS, map3));


% Create beam pattern.
i_channel = (1:NUM_CHANNELS)-1;
i_beam = (1:NUM_BEAMS)-1;

% Spread beams over -pi/4 to +pi/4
theta_beam = -pi/4 + (pi/2)*i_beam/(NUM_BEAMS-1);
steering_phase = 2.*pi*D_OVER_LAMBDA*(transpose(sin(theta_beam))*i_channel);

% Compute steering vectors.
steering_vectors = exp(i*steering_phase);

% Compute pulse-shape.
i_pulse_shape = transpose((1:PULSE_SIZE)-1);
pulse_phase = (i_pulse_shape/PULSE_SIZE - 0.5).^2*PULSE_SIZE;
pulse_shape = exp(i*pulse_phase);
kernel = fliplr(conj(pulse_shape));

% Create target positions
target_positions = GeneratorProcessor_Targets(NUM_TARGETS,NUM_SAMPLES,NUM_BEAMS,NUM_TIME);

% Set up figure window.
if (SHOWME)
  figure
end
t_stages(1,1) = toc;

% Loop over time steps.
for i_time=1:NUM_TIME

  tic;
  % Initialize data uses parallel assign.
  X0(:,:) = Xrand;

  % Step 0: Insert targets.
  for i_target=1:NUM_TARGETS
    i_s = target_positions(i_time,i_target,1);
    i_c = target_positions(i_time,i_target,2);
    X0(i_s,i_c) = 1;  % Applies only to "owner" of (i_s,i_c).
  end % for i_target
  t_stages(i_time,2) = toc;

  % Step 1: Convolve with pulse Corner turn.
  % conv2 has been overloaded to handle this parallel case.
  % X1 has a different mapping than X0, so communication
  % takes place implicity via "="
  tic
  X1(:,:) = conv2(X0,pulse_shape,'same');
  t_stages(i_time,3) = toc;

  % Step 2: Create channel response and Corner turn.
  % "*" has been overloaded to handle this parallel case.
  % X2 has a different mapping than X1, so communication
  % takes place implicity via "="
  tic
  X2(:,:) = X1*steering_vectors;
  t_stages(i_time,4) = toc;

  % Step 3: Compress pulse and Corner turn.
  % conv2 has been overloaded to handle this parallel case.
  % X3 has a different mapping than X2, so communication
  % takes place implicity via "="
  tic
  X3(:,:) = conv2(X2,kernel,'same');
  t_stages(i_time,5) = toc;

  % Step 4: Form beams.
  % "*" has been overloaded to handle this parallel case.
  % X4 has the same mapping as X3, so NO communication
  % takes place.
  tic
  X4(:,:) = X3*ctranspose(steering_vectors);
  t_stages(i_time,6) = toc;

  % Step 5: Find targets.
  % abs, ">" and find hav been overloaded to handle
  % this parallel case.  Finds sends all results
  % back to leader.  Many other behaviors are possible.
  tic
  [i_range,i_beam] = find(abs(X4) > DET_THRESHOLD);

  % Display results.
  if (SHOWME)
    plot(i_range,i_beam,'o');
    axis([1 NUM_SAMPLES 1 NUM_BEAMS]);
    pause(0.2);
  end
  t_stages(i_time,7) = toc;

end % for i_time

% Display times.
t_stages

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
