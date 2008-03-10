function out = subsref(A,s)

  switch (s(1).type)
   case {'()','{}'}
    if length(s) > 1	
      out=subsref(A(s(1).subs{:}), s(2:end));
    else
      out = A(s(1).subs{:});
    end    
   case '.',
    if ismember(s(1).subs,fieldnames(A))
      if length(s) > 1
	out = eval(['subsref( A.' s(1).subs ',s(2:end))']);
      else
 	if length(A) > 1
 	  out = eval(['{A.' s(1).subs '}']);
 	else
 	  out = eval(['A.' s(1).subs]);
 	end
      end
    else
      error(lasterr)
    end
  end
  
return
%from subsasgn
      for n=1:length(A)
	if length(s) > 1
	  eval(['A(n).' s(1).subs ' = subsasgn(A(n).' s(1).subs ',s(2:end),b(n,:));']);
	else
	  eval(['A(n).' s(1).subs '=b(n,:);']);
	end
      end
 