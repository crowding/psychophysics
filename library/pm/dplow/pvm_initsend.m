function bufid=pvm_initsend(encoding)
%PVM_INITSEND
%	Clear default send buffer and specify message encoding.
%	
%	Synopsis:
%		bufid = pvm_initsend(encoding)
%
%	Parameters:
%		encoding
%			Integer specifying next message's encoding scheme
%			Value   Encoding	Meaning
%			0	PvmDataDefault	XDR
%			1	PvmDataRaw	no encoding
%			2	PvmDataInPlace	data left in place
%
%		bufid	Integer returned containing the message buffer 
%			identifier. Values less than zero indicate an error.
%		   	Error Value	Possible cause
%			PvmBadParam	giving an invalid encoding value
%			PvmNoMem	Malloc has failed. There is not
%					enough memory to create the buffer.
%
%	See also: man pvm_initsend(3PVM)

%	Copyright (c) 1995-1999 University of Rostock, Germany, 
%	Institute of Automatic Control. All rights reserved.
%	Authors: M. Suesse, S. Pawletta

bufid=m2pvm(600,encoding);



