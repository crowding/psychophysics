function A = subsasgn(A,s,b)

  switch (s(1).type)
   case '()'
    if length(s) > 1
      A(s(1).subs{:}) = subsasgn( A(s(1).subs{:}), s(2:end), b );
    else
      A(s(1).subs{:}) = b;
    end   
   case '.',
    %    if ismember(s(1).subs,fieldnames(A))
    try,
      if length(s) > 1
	eval(['A.' s(1).subs ' = subsasgn(A.' s(1).subs ',s(2:end),b);']);
      else
	eval(['A.' s(1).subs '=b;']);
      end
    catch
%      try,
	if length(s) > 1
	  eval(['A.pmrpcfun.' s(1).subs ' = [subsasgn(A.pmrpcfun.' s(1).subs ',s(2:end),b)];']);
	else
	  eval(['A.pmrpcfun.' s(1).subs '=b;']);
	end
%      catch,
%	error(lasterr);
%      end
    end
  end
  
