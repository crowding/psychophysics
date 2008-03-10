function info = prompt_mm
%PROMPT_MM		Script intérprete para instancias MM (uso interno)
%
%	Permite a una instancia MM recibir comandos mmeval
%	  además de atender al teclado como siempre
%
%	hecho function para evitar clear -> workspace propio

[lv ctx mmids gn] = mmlevel;
inum=pvm_getinst(gn, pvm_mytid);
if ~inum,	info=inum; error('prompt_mm: inconsistencia en grupo'), end
if  inum<0,	info=inum; pvm_perror('prompt_mm'), error('inum'), end
in=int2str(inum);

TAGCMD  =  666;
prompt  = [gn ':' in   '>'               ];		%%%%%%%%%%%
fmt_pvm = [             ' from %d>> %s\n'];		% Constants
fmt_kbd = [             '> '             ];		%%%%%%%%%%%

fprintf(prompt);					%%%%%%%%%
MM_CMD    = '' ;					% default
MM_RETNMS = {} ;					%%%%%%%%%

while 1							%%%%%%%%%%%%%%%%
							% Busy Wait Loop
	bufid=pvm_probe(pvm_parent, TAGCMD);		%%%%%%%%%%%%%%%%
    if	bufid<0,	info=bufid; pvm_perror('prompt_mm'), error('probe')
							%%%%%%%%%%%%%
elseif	bufid==0					% Command KBD
							%%%%%%%%%%%%%
	if select,	MM_CMD = input(fmt_kbd, 's'); end
							%%%%%%%%%%%%%
else  %	bufid >0					% Command PVM

	   info=pvm_recv(pvm_parent, TAGCMD);	% en realidad bufid
	if info<0,	pvm_perror('prompt_mm'), error('recv'), end
   [info bfinfo]=pvm_bufinfo(info);
	if info,	pvm_perror('prompt_mm'), error('bufinfo'), end
   [info  names]=pvm_unpack;
	if info,	pvm_perror('prompt_mm'), error('unpack'), end

  [i idxc idxr]=deal(0);				%%%%%%%%%%%%%%
   for n=names,	i=i+1;					% Command/Vars
     if ~isempty(n{1})
	if strcmp(n{1},'MM_CMD'   ), idxc=i; end
	if strcmp(n{1},'MM_RETNMS'), idxr=i; end
     end
   end
							%%%%%%%%%%%%%%
   if xor(idxc,idxr)					% Trim Command
	info=-1; error('prompt_mm: CMD y RETNMS, ambos'), end

   if     idxc,	names(max([idxc idxr]))=[];
		names(min([idxc idxr]))=[]; end

   if ~isempty(names),	MM_VARS='';		%%%%%%%%%%%%%%%%%%
     for n=names				% Vars-> Workspace
	MM_VARS=[MM_VARS ', ' n{1}];
	assignin('base'   ,   n{1}, eval(n{1}));
     end
     fprintf  (fmt_pvm, bfinfo.tid, MM_VARS(3:end))	%%%%%%%%%%%
     fprintf  (prompt);					% echo Vars
   end

   if ~isempty(MM_CMD)
     fprintf  (fmt_pvm, bfinfo.tid, MM_CMD);		%%%%%%%%%%%%%%
     fprintf  (prompt);					% echo Command
   end

   if ~isempty	(MM_RETNMS), MM_RETS='';		%%%%%%%%%%%%%%
     for       n=MM_RETNMS				% Echo Returns
	MM_RETS=[MM_RETS ', ' n{1}];
     end
     fprintf  (fmt_pvm, bfinfo.tid, ['return -> ' MM_RETS(3:end)])
%    fprintf  (prompt);
   end
							% Command PVM %%%
  end %	else bufid>0					%%%%%%%%%%%%%%%%%


  if ~isempty(MM_CMD)				%%%%%%%%%%%%%%
	info=0;					% EVAL Command
    if	~strcmp(strtok(MM_CMD), 'quit') &...	%%%%%%%%%%%%%%
	~strcmp(strtok(MM_CMD), 'exit'), evalin('base',MM_CMD,'info=-1;'), end
    if info,	disp([ char(7) 'MM_CMD??? ' lasterr ]), end

						%%%%%%%%%%%%%%%
    if ~isempty(MM_RETNMS),	MM_RETS='';	% RETURN Result
      for n=MM_RETNMS
	if evalin('base', ['exist('''   n{1}  ''',''var'')'] )
		MM_RETS = [MM_RETS ', ' n{1}];
	else,	MM_RETS = [MM_RETS ', ''MM_NOSUCHVAR'''];
	end
      end,			MM_RETNMS={};

      info=pvm_initsend;
	if info<0,	pvm_perror('prompt_mm'), error('initsend'), end
      evalin('base', [ 'pvme_pack('  MM_RETS(3:end) ');'], 'info=-1' );
	if info==-1,	pvm_perror('prompt_mm'), error('evalin'), end
      info=pvm_send(pvm_parent, TAGCMD);
	if info,	pvm_perror('prompt_mm'), error('send'), end
						% RETURN %%
    end	% ~isempty RETNMS			%%%%%%%%%%%

    if	strcmp(strtok(	MM_CMD), 'quit') |...	%%%%%%%%%%%%%%
	strcmp(strtok(	MM_CMD), 'exit') |...	% era QUIT ó EXIT
	strcmp(strtok(	MM_CMD), 'mmexit')
	if strcmp(strtok(MM_CMD),'mmexit'), MM_CMD='quit'; end
	[level ctx mmids grpnam] = mmlevel;
	 if pvm_lvgroup(grpnam),pvm_perror('mmprompt'), error('lvgroup'), end
	 if pvm_exit,		pvm_perror('mmprompt'), error('pvm_exit'), end
	evalin('base',	MM_CMD, 'error('' no puedo salir? '')')
    end,		MM_CMD='';

    fprintf(prompt);				% EVAL %%
  end	% ~isempty CMD				%%%%%%%%%

end					% Busy Wait %%%
					%%%%%%%%%%%%%%%

