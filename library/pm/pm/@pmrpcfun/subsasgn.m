function A = subsasgn(A,s,b)

  switch (s(1).type)
   case '()'
    if length(s) > 1
      A(s(1).subs{:}) = subsasgn( A(s(1).subs{:}), s(2:end), b );
    else
      A(s(1).subs{:}) = b;
    end   
   case '.',
    if ismember(s(1).subs,fieldnames(A))
      if length(s) > 1
	eval(['A.' s(1).subs ' = subsasgn(A.' s(1).subs ',s(2:end),b);']);
      else
	eval(['A.' s(1).subs '=b;']);
      end
    else
      error('that fieldname does not exist in object');
    end
  end
  
