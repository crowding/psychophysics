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

% pMATLAB SETUP ---------------------
PARALLEL = 0;  % Turn pMatlab on or off. Can be 1 or 0.

pMatlab_Init;                   % Initialize pMatlab.
Ncpus = pMATLAB.comm_size;      % Get number of cpus.
my_rank = pMATLAB.my_rank;      % Get my rank.

Zmap = 1;       % Initialize maps to 1 (i.e. no map).
if (PARALLEL)  
  % Create map that breaks up array along 3rd dimension.
  Zmap = map([1 1 Ncpus], {}, 0:Ncpus-1 );

  % NOTE: ADD OPTION FOR BLOCK-CYCLIC DISTRIBURTION.

end

% Allocate distributed array to hold images.
zoomedFrames = zeros(n_image,n_image,numFrames,Zmap);

% Compute which frames are local along 3rd dimension.
my_frameIndex = global_ind(zoomedFrames,3);

% Compute scale factor.
scaleFactor = linspace(startScale,endScale,numFrames);

% Estimate frames.
disp('Zooming frames...'); tic; 

% Create reference frame.
refFrame = referenceFrame(n_image,0.1,0.8);

% Compute local frames.
my_zoomedFrames = zoomFrames(refFrame,scaleFactor(my_frameIndex),blurSigma);

% Copy back into global array.
zoomedFrames = put_local(zoomedFrames,my_zoomedFrames);

elapsedTime = toc;
disp(['Elapsed time = ',num2str(elapsedTime,'%0.2f'),' sec.']);

% Compute gigaflops.
nelem = ceil(scaleFactor*(5*blurSigma));
totalOps = 2.*sum((nelem.^2)).*(n_image.^2);
GigaFlops = 1.e-9*totalOps/elapsedTime

% Aggregate on leader.
aggFrames = agg(zoomedFrames);

% Print success.
disp('SUCCESS');

% Exit on all but the leader.
pMatlab_Finalize;

% Display simulated frames.
figure(1); clf;
set(gcf,'Name','Simulated Frames','DoubleBuffer','on','NumberTitle','off');
for frameIndex=[1:numFrames]
   imagesc(squeeze(aggFrames(:,:,frameIndex)));
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

