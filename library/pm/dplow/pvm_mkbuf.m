function bufid=pvm_mkbuf(encoding)
%PVM_MKBUF
%	Creates a new message buffer.
%	
%	Synopsis:
%		bufid = pvm_mkbuf(encoding)
%
%	Parameters:
%		encoding
%			Integer specifying the buffer's encoding scheme.
%			Value   Encoding 	Meaning
%			0	PvmDataDefault	XDR
%			1	PvmDataRaw	no encoding
%			2	PvmDataInPlace	data left in place
%
%		bufid	Integer message buffer identifier returned. Values
%			less than zero indicate an error.
%		   	Error Value	Possible cause
%			PvmBadParam	giving an invalid value
%			PvmNoMem	Malloc has failed. There is not
%					enough memory to create the buffer.
%
%	See also: man pvm_mkbuf(3PVM)

%	Copyright (c) 1995-1999 University of Rostock, Germany, 
%	Institute of Automatic Control. All rights reserved.
%	Author: M. Suesse, S. Pawletta

bufid=m2pvm(601,encoding);



