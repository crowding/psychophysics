function out = subsref(A,s)
  switch (s(1).type)
   case {'()','{}'}
    if length(s) > 1	
      out=subsref(A(s(1).subs{:}), s(2:end));
    else
      out = A(s(1).subs{:});
    end    
   case '.',
    try, 
      if length(s) > 1
	eval(['out=[subsref( A.' s(1).subs ',s(2:end))];']);
      else
	if length(A) > 1
	  eval(['out={A.' s(1).subs '};']);
	else
	  eval(['out=A.' s(1).subs ';']);
	end
      end
    catch
      try,
	if length(s) > 1
	  eval(['out=[subsref( A.pmfun.' s(1).subs ',s(2:end))];']);
	else
	  if length(A) > 1
	    eval(['out={A.pmfun.' s(1).subs '};']);
	  else
	    eval(['out=A.pmfun.' s(1).subs ';']);
	  end
	end
      catch
	error(lasterr);
      end
    end
  end