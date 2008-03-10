function out = subsref(A,s)

  switch (s(1).type)
   case '()'
    if length(s) > 1
      out=subsref( A(s(1).subs{:}), s(2:end) );
    else
      out=A(s(1).subs{:});
    end    
   case '.',
    if ismember(s(1).subs,fieldnames(A))
      if length(s) > 1
	eval(['out=subsref( A.' s(1).subs ',s(2:end));']);
      else
	eval(['out=A.' s(1).subs ';']);
      end
    else
      error(lasterr)
    end
  end
  
