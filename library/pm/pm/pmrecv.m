function [mat,dpid,mat_name]=pmrecv(i1,i2,tmout)
%PMRECV	Receive array.
%
%	Full synopsis:
%		[mat,pmid,mat_name]=pmrecv(pmid,mat_name,tmout)
%
%	Input parameters:
%		pmid	specifies the sender from which the array should
%			be received. pmid=[] or pmid=-1 are wildcards,
%			i.e. a array from an arbitrary sender can be
%			received.
%
%		mat_name specifies the name of a array which should be
%			received. mat_name='' is a wildcard, i.e. an
%			arbitrary array can be received.
%
%		tmout	can be +Inf, 0 or a value in between.
%			With tmout=+Inf pmrecv cannot return until a array 
%			is actually received (blocking receive).
%			With tmout=0 pmrecv returns immediatelly even if no 
%			array could be received (non-blocking receive).
%			A value between +Inf and 0 specifies a time period 
%			in seconds (with a maximum accuracy of one micro 
%			second) after which pmrecv returns even if no array 
%			could be received (timout receive).
%
%	Output parameters:
%		mat	is the received array. If no array could be
%			received (possible when tmout<+Inf) mat is the
%			empty array [].
%
%		pmid	is the sender identification from which the array
%			has been received (useful when pmid was a wildcard
%			as input parameter).
%			If no array could be received pmid is the empty
%			array []. The only save test whether a array has
%			actually received or not (when tmout<+Inf) is to
%			check with isempty(pmid). The tests isempty(mat) or 
%			isempty(mat_name) are not save, because received
%			matrices may be empty or unnamed.
%			
%		mat_name is the name of the received array (useful when
%			mat_name was a wildcard as input parameter).
%			If no array could be received mat_name is an
%			empty string ''.
%
%	Short forms:
%		pmrecv	blocking receive of an arbitrary array from an
%			arbitrary sender.
%
%		pmrecv(mat_name) blocking receive of a particular array
%			from an arbitrary sender.
%
%		pmrecv(pmid) blocking receive of an arbitrary array from
%			a particular sender.
%
%		pmrecv(pmid,mat_name) blocking receive of a particular array
%			from a particular sender.

%       This function is taken from the DPRECV in the DP-toolbox.
%	Copyright (c) 1995-1999 University of Rostock, Germany,
%	Institute of Automatic Control. All rights reserved.
%	Author: S. Pawletta


% Constants
DpMsgTag = 9000;


% Analyse signature
if     nargin == 0
	dpid     = -1;
	mat_name = '';
	tmout    = +Inf;
elseif nargin == 1
	if isstr(i1)
		dpid     = -1;
		mat_name = i1;
	else
		dpid     = i1;
		mat_name = '';
	end
	tmout	 = +Inf;
elseif nargin == 2
	dpid     = i1;
	mat_name = i2;
	tmout    = +Inf;
else
	dpid     = i1;
	mat_name = i2;
end


% Adjust dpid if it is a wildcard
if isempty(dpid)
	dpid = -1;
end


% Remove trailing blanks from mat_name
mat_name = deblank(mat_name);


% Open persistent dprecv message list
DPRECVLIST = [];
DPRECVLIST_NAMES = [];
persistent2('open','DPRECVLIST');
persistent2('open','DPRECVLIST_NAMES');
DPRECVLIST_NAMES = char(DPRECVLIST_NAMES);


% Receiving loop
if 0 < tmout  &  tmout < +Inf
	% Start time for timeout receive
	tstart = clock;
end
while 1

	% Match against dprecv message list
%	disp('% Match against dprecv message list')
	match = [];
	if ~isempty(DPRECVLIST)
		if     dpid == -1 & isempty(mat_name)

			% any sender, any mat_name
%			disp('% any sender, any mat_name')
 
			% take first message
%			disp('% take first message')
			match = 1;

		elseif dpid ~= -1 & isempty(mat_name)

			% certain sender, any mat_name
%			disp('% certain sender, any mat_name')
 
			% match against dpid
%			disp('% match against dpid')
			match = find(DPRECVLIST(:,1)==dpid);
			if length(match) > 1
				match = match(1);
			end

		elseif dpid == -1 & ~isempty(mat_name)

			% any sender, certain mat_name
%			disp('% any sender, certain mat_name')
 
			% match against mat_name
%			disp('% match against mat_name')
			for i = 1:size(DPRECVLIST,1)
				if strcmp(deblank(DPRECVLIST_NAMES(i,:)),mat_name)
					match = i;
					break;
				end
			end

		else

			% certain sender, certain mat_name
%			disp('% certain sender, certain mat_name')
 
			% match against dpid
%			disp('% match against dpid')
			match = find(DPRECVLIST(:,1)==dpid);

			if match
				match_dpid = match;
				match = [];

				% match against mat_name in question
%				disp('% match against mat_name in question')
				for i = 1:length(match_dpid)
					if strcmp(deblank(DPRECVLIST_NAMES(match_dpid(i),:)),mat_name)
						match = match_dpid(i);
						break;
					end
				end
			end
		end
	end
	% End of match against dprecv message list
%	disp('% End of match against dprecv message list')
%	match


	if match

		% Exit receiving loop with match
%		disp('% Exit receiving loop with match')
		break;
	end


	% Match against pvm message list
%	disp('% Match against pvm message list')
	if     tmout == +Inf

		% Blocking receive
%		disp('% Blocking receive')
 
		bufid = pvm_recv(-1,DpMsgTag);
		if bufid<0 error('pvm_recv failed.'), end
		
	elseif tmout == 0

		% Non-blocking receive
%		disp('% Non-blocking receive')

		bufid = pvm_nrecv(-1,DpMsgTag);
		if bufid<0 error('pvm_nrecv failed.'), end
		if bufid == 0

			% Exit receiving loop with no match
%			disp('% Exit receiving loop with no match')
			match = []; break;
		end

	else

%%%%%% The following is modified in the PM Toolbox compared to DP.
%----------------------------------------------1
		% Timeout receive
%		disp('% Timeout receive')

		% Timeout reached ?
%		trest = tmout - etime(clock,tstart)
%		if trest < 0
			% Timeout reached
%			disp('% Timeout reached')

			% Exit receiving loop
%			break
%		end
		
		sec = fix(tmout);
		usec = (tmout-sec) * 10^6;
%----------------------------------------------1
		bufid = pvm_trecv(-1,DpMsgTag,sec,usec);
		if bufid<0 error('pvm_trecv failed.'), end
		if bufid == 0

			% Exit receiving loop with no match
%			disp('% Exit receiving loop with no match')
			match = []; break;
		end

	end
	% End of match against pvm message list
%	disp('% End of match against pvm message list')


	% Append match to dprecv message list
%	disp('% Append match to dprecv message list')
	[drop,drop,dpid_tmp,info] = pvm_bufinfo(bufid);
	if info<0 error('pvm_bufinfo failed.'), end
	v = version;
	if v(1) == '4'
		[mat_name_tmp,info] = pvme_upkmat_name;
	else
		[mat_name_tmp,info] = pvme_upkarray_name;
	end
	info = pvm_setrbuf(0);
	if info<0 error('pvm_setrbuf failed.'), end
	DPRECVLIST = [DPRECVLIST; dpid_tmp bufid];
	if isempty(mat_name_tmp)
		DPRECVLIST_NAMES = strvcat(DPRECVLIST_NAMES,' ');
	else
		DPRECVLIST_NAMES = strvcat(DPRECVLIST_NAMES,mat_name_tmp);
	end
end
% End of receiving loop


if match

	% Return match
%	disp('% Return match')
	info = pvm_setrbuf(DPRECVLIST(match,2));
	if info<0 error('pvm_setrbuf failed.'), end
	v = version;
	if v(1) == '4'
		[mat,info] = pvme_upkmat_rest;
		if info<0 error('pvme_upkmat_rest failed.'), end
	else
		[mat,info] = pvme_upkarray_rest;
		if info<0 error('pvme_upkarray_rest failed.'), end
	end
	info = pvm_freebuf(DPRECVLIST(match,2));
	if info<0 error('pvme_freebuf failed.'), end
	dpid  = DPRECVLIST(match,1);
	mat_name = deblank(DPRECVLIST_NAMES(match,:));

	% Remove match from dprecv message list
%	disp('% Remove match from dprecv message list')
	n = size(DPRECVLIST,1);
	DPRECVLIST       = DPRECVLIST([1:match-1,match+1:n],:);
	DPRECVLIST_NAMES = DPRECVLIST_NAMES([1:match-1,match+1:n],:);
else
	
	% Return no match
	mat      = [];
	dpid     = [];
	mat_name = '';
end


% Close persistent dprecv message list
persistent2('close','DPRECVLIST');
DPRECVLIST_NAMES = double(DPRECVLIST_NAMES);
persistent2('close','DPRECVLIST_NAMES');


return

