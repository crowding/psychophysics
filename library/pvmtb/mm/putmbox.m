function f = putmbox(key, varargin)
%PUTMBOX		Secuencia initsend/pack/putinfo (uso interno)

f = -1;

bufid=pvm_initsend;		if bufid<0,pvm_perror('putmbox'), return, end
info =pvm_pack   (varargin);	if info,   pvm_perror('putmbox'), return, end
index=pvm_putinfo(key, bufid,0);if index,  pvm_perror('putmbox'), return, end

f =  0;

