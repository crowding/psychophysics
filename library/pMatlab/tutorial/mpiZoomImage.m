%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ZoomImage: zoom in on an image.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set zoom parameters.
n_image = 256;     % Size of image.
numFrames  = 32;   % number of frames
startScale = 32;   % Starting scale.
endScale = 1;     % Ending scale.
% Bluring parameters.
blurSigma  = 0.5;  % std. dev. of blur kernel (in pixels) 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Setup the MPI world.
MPI_Init;   % Initialize MPI.
comm = MPI_COMM_WORLD;   % Create communicator.
% Get size and rank.
Ncpus = MPI_Comm_size(comm);
my_rank = MPI_Comm_rank(comm);

% Set who is the leader
leader = 0;

% Create base message tags.
input_tag = 20000;
output_tag = 30000;


% Print rank.
disp(['my_rank: ',num2str(my_rank)]);


% Compute scale factor.
scaleFactor = linspace(startScale,endScale,numFrames);

% Print rank.

% Compute indices for each image.
frameIndex = 1:numFrames;
% Deal out images to each processor.
frameRank = mod(frameIndex,Ncpus);
if (my_rank == leader)
  disp(['Sending frame indices.']);
  % Loop over all processors.
  for dest_rank=0:Ncpus-1
    % Find frame indices to send.
    dest_data = find(frameRank == dest_rank);
    % Copy or send.
    if (dest_rank == leader)
      my_frameIndex = dest_data;
    else
      MPI_Send(dest_rank,input_tag,comm,dest_data);
    end
  end
end


% Everyone but the leader receives the data.
if (my_rank ~= leader)
  % Receive data.
  disp(['Receiving frame indices.']);
  my_frameIndex = MPI_Recv( leader, input_tag, comm );
end

% Estimate frames.
disp('Zooming frames...'); tic; 


% Create reference frame.
refFrame = referenceFrame(n_image,0.1,0.8);

% Do computation.
my_zoomedFrames = zoomFrames(refFrame,scaleFactor(my_frameIndex),blurSigma);
elapsedTime = toc;
disp(['Elapsed time = ',num2str(elapsedTime,'%0.2f'),' sec.']);

% Everyone but the leader sends the data back.
if (my_rank ~= leader)
  % Send images back to tleader
  disp(['Sending images.']);
  MPI_Send(leader,output_tag,comm,my_zoomedFrames);
end


% Leader receives data.
if (my_rank == leader)
  disp(['Receiving images.']);
  % Allocate array to hold data.
  zoomedFrames = zeros(n_image,n_image,numFrames);
  % Loop over all processors.
  for send_rank=0:Ncpus-1
    % Find frame indices to send.
    send_frameIndex = find(frameRank == send_rank);
    % Copy or receive.
    if (send_rank == leader)
      zoomedFrames(:,:,send_frameIndex) = my_zoomedFrames;
    else
      zoomedFrames(:,:,send_frameIndex) = ...
         MPI_Recv( send_rank, output_tag, comm );
    end
  end
end


% Compute gigaflops.
nelem = ceil(scaleFactor*(5*blurSigma));
totalOps = 2.*sum((nelem.^2)).*(n_image.^2);
GigaFlops = 1.e-9*totalOps/elapsedTime


% Shut down everyone but leader.
disp('SUCCESS');
MPI_Finalize;

if (my_rank ~= leader)
    exit;
end

% Display simulated frames.
figure(1); clf;
set(gcf,'Name','Simulated Frames','DoubleBuffer','on','NumberTitle','off');
for frameIndex=[1:numFrames]
   imagesc(squeeze(zoomedFrames(:,:,frameIndex)));
   drawnow;
end

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

