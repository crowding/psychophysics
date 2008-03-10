function [info,msg] = pvme_upkntfy()
%PVME_UPKNTFY		Desempaqueta mensaje de notificación
%
%  [info msg] = pvme_upkntfy
%
%  info(int)	código de retorno
%  msg (int/arr)vector de enteros de la notificación
%
%	pvm_unpack no sirve para desempaquetar mensaje notificación,
%	  ya que no son variables Matlab empaquetadas con pvm_pack.mexlx
%	Afortunadamente, los mensajes de notificación son siempre int arrays
%	  lo que permite usar pvm_upkint aunque sea de uno en uno
%
%  Implementación M completa

[info n]=pvm_upkint;
if info, pvm_perror('pvme_upkntfy'), end

if n<262144	% 0x40000	% Tamaño array o TID sencillo?
	msg=zeros(n,1);		% Tamaño array
	for i=1:n
	   [info msg(i)] = pvm_upkint;
	   if info, pvm_perror('pvme_upkntfy'), break, end
	end
else,	msg = n;		% TID sencillo
end

