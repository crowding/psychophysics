function strct__ = str2struct(str__)
%convert the strings in log files back to structs

%if it's assignments, this is easy. It is assigments if it contains an
%equals sign. (Old style datas contain no equals signs.

if any(str__ == '=') 
    %it's assignments. Evaluate them:
    eval(str__);
    %Return as a struct:
    vars = who();
    strct__ = struct();
    for i = vars(:)'
        if ~isequal(i{:}, 'str__');
           strct__.(i{:}) = eval(i{1});
        end
    end
else
    %if it's the other format:
    %you get a bunch of variable names and a bunch of words.
    [varnames, index] = regexp(str__, '^(\s*(?!NaN)[a-zA-Z][a-zA-Z0-9_]*)*', 'match', 'end');
    varnames = regexpsplit(varnames{1}, '\s+');
        values = eval(['{' str__(index+1:end) '}']);
    
    args = cat(1, varnames, values);
    strct__ = struct(args{:});
end