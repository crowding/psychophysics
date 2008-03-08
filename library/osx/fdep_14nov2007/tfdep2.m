%TFDEP2		FDEP test script
%		this function must no be used
%		it contains raw function calls only
%
%SYNTAX
%		do not run
%
%EXAMPLE
%		do not run

% created:
%	us	01-Mar-2007
% modified:
%	us	14-Nov-2007 13:16:06

%--------------------------------------------------------------------------------

% put your favorite function below
	chkoptn;
% put your favorite function abov
	sfig=1;			% variable
	foo0=@(x) cosd(x);	% function handles
	goo0=@(x)...
		sprintf('%f',exp(x));
	sind;			% ML built-in
	unique;			% ML function
	ismember=12;		% note: DEFUN will not handle this in a SCRIPT
	eval;			% call to EVAL...
	tfdep1;			% call test function 1
	tfdep2;			% recursion
	pfdep4;			% call a standalone P-file