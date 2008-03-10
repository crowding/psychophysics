function [] = pmextern()
%PMEXTERN Set the PM console to extern mode.
%   PMEXTERN switches the Matlab console of a PMI into EXTERN mode which
%   allows it to receive and execute PMEVAL,PMRPC,PMPUT,PMGET requests
%   from other instances. If a key is pressed in the console the PMI will
%   go back to normal interactive mode as soon as the task currently
%   evaluating has terminated.
%
%   See also PMEVAL, PMRPC, PMPUT, PMGET, PMGETMODE.
  
% constants

PMINTERACTIVE = 0;
PMEXTERN      = 1;
EvalMsgTag    = 9010;
pm_setinfo(PMEXTERN,'');
pstr     = [sprintf('%d',pvm_mytid) '>'];
pstr_pvm = '%d>> %s\n';
v = version; v = v(1);
keypressed = 0;

fprintf(pstr);
BACKGROUND = [];
persistent2('open','BACKGROUND')
keypressed = selectstdin(0);
while ~keypressed | ~isempty(BACKGROUND)
  try,
    if ~isempty(BACKGROUND)
      % PMEVAL?
      bufid = pvm_recv(-1,EvalMsgTag); %blocking receive
      if bufid < 0
	error(['pmextern: pvm_recv() failed.' int2str(bufid)])
      end
    else
      drawnow;
      % PMEVAL?
      bufid = pvm_trecv(-1,EvalMsgTag,0,100000); %timed out receive
      if bufid < 0
	error(['pmextern: pvm_trecv() failed.' int2str(bufid)])
      end
    end
    if bufid > 0
      [trash,trash,stid] = pvm_bufinfo(bufid);
      if v == '4'
	cmd_str = pvme_upkmat;
      else
	cmd_str = pvme_upkarray;
      end
      pvm_freebuf(bufid);
      % find out length of standard setup of global variables.
      if cmd_str(1) == 'Q'
	quiet_mode = 1;
      else
	quiet_mode = 0;
      end
      [t,cmd_str] = strtok(cmd_str(2:end),'#');
      [cmd_str,catch_expr] = strtok(cmd_str(2:end),'#');
      len = str2num(t);
      pm_setinfo(PMEXTERN,cmd_str(len:end));
      if ~quiet_mode
	fprintf(pstr_pvm,stid,cmd_str(len:end));
      end
      if isempty(catch_expr)
	evalin('caller',cmd_str)
      else
	evalin('caller',cmd_str,'evalin(''caller'',catch_expr(2:end))')
      end
      if ~quiet_mode
	fprintf('%s',pstr);
      end	
      pm_setinfo(PMEXTERN,'');
      end
      keypressed = selectstdin(0);
  catch,
    global PMEVALPARENT
    le = lasterr;
    pmsend(PMEVALPARENT,le,'EVAL_ERROR');
    if ~quiet_mode
      fprintf('??? %s\n\n',le);
      fprintf(pstr);
    end
    clear PMEVALPARENT
    % restart!
    % it's looping instead of calling itself to prevent it from eating
    % memory for each new function workspace initialised.
  end
end
pm_setinfo(PMINTERACTIVE,'');













