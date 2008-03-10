function out = subsref(A,s)
  switch (s(1).type)
   case '()'
    if length(s) > 1
      out=[subsref(A(s(1).subs{:}), s(2:end) )];
    else
      out=[A(s(1).subs{:})];
    end    
   case '.',
    try, 
      if length(s) > 1
	eval(['out=[subsref( A.' s(1).subs ',s(2:end))];']);
      else
	eval(['out=[A.' s(1).subs '];']);
      end
    catch
      try,
	if length(s) > 1
	  eval(['out=[subsref( A.pmrpcfun.' s(1).subs ',s(2:end))];']);
	else
	  eval(['out=[A.pmrpcfun.' s(1).subs '];']);
	end
      catch
	error(lasterr);
      end
    end
  end
  
