%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% pBeamformer is an example of a simple parallel beamformer.
% The first have generates synthetic
% data and then passes the data into to the second half
% which processes the data.
%
% To run, edit RUN.m, start Matlab and type:
%
%   RUN
%
% Output will be piped into to
%
%   MatMPI/pBeamformer.0.out
%   MatMPI/pBeamformer.1.out
%   ...
%
% Edit pBeamformer to change behavior.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
% pBeamformer Example: Brian Tracey (tracey@ll.mit.edu)
% pMatlab: Parallel Matlab Toolbox
% Software Engineer: Ms. Nadya Travinin (nt@ll.mit.edu)
% Architect: Dr. Jeremy Kepner (kepner@ll.mit.edu)
% MIT Lincoln Laboratory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% pMATLAB SETUP ---------------------
PARALLEL = 0;  % Turn pMatlab on or off. Can be 1 or 0.
PROFILE = 0;    % Turn profiler on or off. Can be 1 or 0.

if (PROFILE)
  profile on
end
tic;	% Start timer.

pMatlab_Init;			% Initialize pMatlab.
Ncpus = pMATLAB.comm_size;	% Get number of cpus.
my_rank = pMATLAB.my_rank;	% Get my rank.

Xmap = 1;	% Initialize maps to 1 (i.e. no map).
if (PARALLEL)  
  % Create map that breaks up array along 2nd dimension.
  Xmap = map([1 Ncpus 1], {}, 0:Ncpus-1 );
end

% ALLOCATE PARALLEL DATA STRUCTURES ---------------------

% Set array dimensions (always test on small probems first).
Nsensors = 90;  Nfreqs = 200;  Nsnapshots = 100;  Nbeams = 80;

% Initial array of sources.
%X0 = complex(zeros(Nsnapshots,Nfreqs,Nbeams,Xmap));
X0 = zeros(Nsnapshots,Nfreqs,Nbeams,Xmap);

% Synthetic sensor input data.
X1 = complex(zeros(Nsnapshots,Nfreqs,Nsensors,Xmap));

% Beamformed output data.
X2 = zeros(Nsnapshots,Nfreqs,Nbeams,Xmap);

% Intermediate summed image.
X3 = zeros(Nsnapshots,Ncpus,Nbeams,Xmap);


% CREATE STEERING VECTORS ---------------------
% Pick an arbitrary set of frequencies.
freq0 = 10;  frequencies = freq0 + (0:Nfreqs-1);

% Get frequencies local to this processor.
[myI_snapshot myI_freq myI_sensor] = global_ind(X1);
myFreqs = frequencies(myI_freq);

% Create local steering vector by passing local frequencies.
myV = squeeze(pBeamformer_vectors(Nsensors,Nbeams,myFreqs));

% STEP 0: Insert targets ---------------------

% Get local data.
X0_local = local(X0);

% Insert two targets at different angles.
X0_local(:,:,round(0.25*Nbeams)) = 1;
X0_local(:,:,round(0.5*Nbeams)) = 1;


% STEP 1: CREATE SYNTHETIC DATA. ---------------------

% Get the local arrays.
X1_local = local(X1);

% Loop over snapshots, then over the local freqencies.
for i_snapshot=1:Nsnapshots
  for i_freq=1:length(myI_freq)
    % Convert from beams to sensors.
    X1_local(i_snapshot,i_freq,:) = ...
      squeeze(myV(:,:,i_freq)) * squeeze(X0_local(i_snapshot,i_freq,:));
  end
end

% Put local array back.
X1 = put_local(X1,X1_local);

% Add some noise,
X1 = X1 + (Nsensors^0.5)*complex( ...
       rand(Nsnapshots,Nfreqs,Nsensors,Xmap), ...
       rand(Nsnapshots,Nfreqs,Nsensors,Xmap) );

% STEP 2: BEAMFORM AND SAVE DATA. ---------------------

% Get the local arrays.
X1_local = local(X1);
X2_local = local(X2);

% Loop over snapshots, loop over the local fequencies.
for i_snapshot=1:Nsnapshots
  for i_freq=1:length(myI_freq)
    % Convert from sensors to beams.
    X2_local(i_snapshot,i_freq,:) = ...
      abs(squeeze(myV(:,:,i_freq))' * squeeze(X1_local(i_snapshot,i_freq,:))).^2;
  end
end

processing_time = toc

% Save data (1 file per freq).
for i_freq=1:length(myI_freq)
   % Get the beamformed data.
   X_i_freq = squeeze(X2_local(:,i_freq,:));

   % Get the global index of this fequencie.
   i_global_freq = myI_freq(i_freq);
   filename = ['dat/pBeamformer_freq.' num2str(i_global_freq) '.mat'];

   % Save to a file.
   save(filename,'X_i_freq');
end


% STEP 3: SUM ACROSS FREQUNCY. ---------------------

% Sum local part across fequency.
X2_local_sum = sum(X2_local,2);

% Put into global array.
X3 = put_local(X3,X2_local_sum);

% Aggregate X3 back to the leader for display.
x3 = agg(X3);


% STEP 4: Finalize and display. ---------------------

% Save profile data.
if (PROFILE)
  profileOutput(my_rank);
end

% Print success.
disp('SUCCESS');

% Exit on all but the leader.
pMatlab_Finalize;

% Display
% Complete local sum.
x3_sum = squeeze(sum(x3,2));

imagesc( abs(squeeze(X0_local(:,1,:))) );
pause(1.0);
figure;
imagesc( abs(squeeze(X1_local(:,1,:))) );
pause(1.0);
figure;
imagesc( abs(squeeze(X2_local(:,1,:))) );
pause(1.0);
figure;
imagesc(x3_sum);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Copyright (c) 2005, Massachusetts Institute of Technology All rights     %
%reserved.                                                                %
%                                                                         %
%Redistribution and use in source and binary forms, with or without       %
%modification, are permitted provided that the following conditions are   %
%met:                                                                     %
%     * Redistributions of source code must retain the above copyright    %
%       notice, this list of conditions and the following disclaimer.     %
%     * Redistributions in binary form must reproduce the above copyright %
%       notice, this list of conditions and the following disclaimer in   %
%       the documentation and/or other materials provided with the        %
%       distribution.                                                     %
%     * Neither the name of the Massachusetts Institute of Technology nor %
%       the names of its contributors may be used to endorse or promote   %
%       products derived from this software without specific prior written% 
%       permission.                                                       %
%                                                                         %
%THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS  %
%IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,%
%THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR   %
%PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR         %
%CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,    %
%EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,      %
%PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR       %
%PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF   %
%LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING     %
%NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS       %
%SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

