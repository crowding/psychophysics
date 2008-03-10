function info=pvme_default_config(conf)
%PVM_DEFAULT_CONFIG
%	Saves a PVM default configuration.
%	
%	Synopsis:
%		info = pvme_default_config(conf)
%
%	Parameters:
%		conf	Multi-string matrix containing pvmd options and
%			hostfile informations,
%			or the name of a hostfile that can be found
%			along the Matlab search path.
%
%		info	Integer status code. Values less than zero indicate 
%			an error.
%		   	Error Value	Possible cause
%			PvmeErr
%
%	See also: 

%	Copyright (c) 1998-1999 University of Rostock, Germany, 
%	Institute of Automatic Control. All rights reserved.
%	Author: S. Pawletta
%               E. Svahn Nov 2000: 
%                  closing file after use. Char instead of setstr

hostfile = which(conf);
if ~isempty(hostfile)
	fid = fopen(hostfile);
	content = fread(fid);
	fclose(fid);
	conf = char(content');
end
info=m2pvm(106,conf);

