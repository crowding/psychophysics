function R = ClutterSim_CovMat(N_es,N_tt)
% Generates a space-time covariance matrix with N_es spatial elements
% and N_tt temporal elements
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Designed by Dr. Nick Pulsone / MIT Lincoln Lab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

dol = 0.5;	      % Element spacing to wavelength ratio (d/lambda)
es_jnr_dB = 30;   % Element-space jammer to noise ratio
bf = 0.05;        % bf = bw / fo, bw = bandwidth, fo = center frequency
foTs = 0.5/bf;    % Note: foTs*bf must be less than or equal to 1
                  % Ts = sampling time between succesive time taps
j2pi = j*2*pi;
es_jnr = 10^(es_jnr_dB/10);

R_temp = zeros(N_es,N_es*N_tt);   % one row of the Block Toeplitz Cov. Matrix
R = zeros(N_es*N_tt,N_es*N_tt);   % complete Block Toeplitz Cov. Matrix
tao_matrix =  sin(-45*pi/180)*dol*toeplitz([0:N_es-1],[0:-1:-N_es+1]);

esi = [1:N_es];
for tt = 0:N_tt-1
    bw_taper = sinc(tao_matrix*bf + bf*foTs*(-tt));
    R_temp(esi,esi+tt*N_es) = (es_jnr*exp(j2pi*(tao_matrix + ...
        foTs*(-tt))).*bw_taper);
end
R_temp(esi,esi) = R_temp(esi,esi) + eye(N_es);  % adds diagonal loading 
R = ClutterSim_BlockTop(R_temp);

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