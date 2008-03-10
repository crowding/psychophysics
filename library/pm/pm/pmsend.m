function pmsend(dpids,mat,mat_name)
%PMSEND	Send array.
%
%       pmsend(pmids,mat) sends an arbitrary array mat to all destinations 
%	specified by pmids. The sender may be one of the destinations. 
%	If more than one array shall be sent, put them together into mat.
%
%	pmsend(pmids,mat,mat_name) sends the array mat under the name
%	given in mat_name. The string mat_name must be a Matlab conform 
%	array name (less than 20 characters in M4 and some more in M5).

%       This function is taken from the DPSEND in the DP-toolbox.
%	Copyright (c) 1995-1999 University of Rostock, Germany,
%	Institute of Automatic Control. All rights reserved.
%	Author: S. Pawletta


% Constants
PvmDataDefault	= 0;
DpMsgTag 	= 9000;


% Analyse signature
if nargin < 3
	mat_name = '';
end


% Init send buffer
bufid = pvm_initsend(PvmDataDefault);
if bufid < 0
	error('dpsend.m: pvm_initsend.m failed.')
end


% Pack matrix
v = version;
if v(1) == '4'
	info = pvme_pkmat(mat,mat_name);
	if info < 0
		error('dpsend.m: pvme_pkmat.m failed.')
	end
else
	info = pvme_pkarray(mat,mat_name);
	if info < 0
		error('dpsend.m: pvme_pkarray.m failed.')
	end
end


% Send matrix
if length(dpids) == 1

	% Single send
	info = pvm_send(dpids,DpMsgTag);
	if info < 0
		error('dpsend.m: pvm_send.m failed.')
	end
else

	% Multiple send

	% Check whether sender is among destinations
	mytid = pvm_mytid;
	if any(dpids == mytid)

		% Sender is one of the destinations;
		% do single send to sender
		info = pvm_send(mytid,DpMsgTag);
		if info < 0
			error('dpsend.m: pvm_send.m failed.')
		end

		% Remove sender as destination
		dpids = dpids(dpids~=mytid);
	end

	% Mcast to all foreign destionations
	info = pvm_mcast(dpids,DpMsgTag);
	if info < 0
		error('dpsend.m: pvm_mcast.m failed.')
	end
end

