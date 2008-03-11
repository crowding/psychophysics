function target_positions=GeneratorProcessor_Targets(NUM_TARGETS,NUM_SAMPLES,NUM_CHANNELS,NUM_TIME)
% Generate some moving targets.

  % Allocate arrays.
  target_positions = zeros(NUM_TIME,NUM_TARGETS,2);
  starting_positions = zeros(NUM_TARGETS,2);

  % Define legs.
  leg1 = 1:(NUM_TARGETS/4);
  leg2 = (NUM_TARGETS/4+1):(NUM_TARGETS/2);
  leg3 = (NUM_TARGETS/2+1):(3*NUM_TARGETS/4);
  leg4 = (3*NUM_TARGETS/4+1):NUM_TARGETS;

  % Define starting positions.
  starting_positions(leg1,1) = 1;
  starting_positions(leg1,2) = NUM_CHANNELS*(leg1'/(NUM_TARGETS/4));
  starting_positions(leg2,1) = 1 + 0.1*NUM_SAMPLES*((leg1-1)'/(NUM_TARGETS/4));
  starting_positions(leg2,2) = 1;
  starting_positions(leg3,1) = 0.11*NUM_SAMPLES;
  starting_positions(leg3,2) = 1+NUM_CHANNELS*((leg1-1)'/(NUM_TARGETS/4));
  starting_positions(leg4,1) = 0.01*NUM_SAMPLES + 0.1*NUM_SAMPLES*(leg1'/(NUM_TARGETS/4));
  starting_positions(leg4,2) = NUM_CHANNELS;

  % Move at each times step.
  for i_time=1:NUM_TIME
    sample_offset =  ((i_time-1)/NUM_TIME)*0.9*NUM_SAMPLES;
    target_positions(i_time,:,1) = starting_positions(:,1) + sample_offset;
    channel_stretch =  cos(2*pi*((i_time-1)/NUM_TIME))^2;
    target_positions(i_time,:,2) = starting_positions(:,2) .* channel_stretch;
  end

 target_positions = max(round(target_positions),1);
 
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
