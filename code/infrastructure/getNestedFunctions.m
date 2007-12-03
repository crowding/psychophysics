function nested = getNestedFunctions(filepath, fpath)
%function nested = getNestedFunctions(fileoath, fpath)
%
%Returns a cell array of the names of the nested functions defined in the
%function path given in the file given.
%
%fpath is the 'complete name' of the function in question. (as returned by
%dstack('-completenames')

fpath = splitstr('/', fpath);

%Use mlint to parse the m-file and print a list of all functions.
filename = getOutput(2, @fileparts, filepath);
text = mlint(filepath, '-calls', '-string');

%parse the function call list into structs
funinfo = textscan(text, '%[MEANUS]%d%d%d%s', 'returnOnError', 0);
funinfo = struct('type', funinfo{1}, 'level', num2cell(funinfo{2}), 'line', num2cell(funinfo{3}), 'name', funinfo{5});

%We will collect method names here
nested = {};

%We scan for nested functions that are defined within the calling function
j = 0;
lineuntil = 0;
for i = funinfo(:)'
    lev = i.level;
    
    if j < numel(fpath)
        %Walking into where the calling function is defined in the file...
        if (j == 0) && (lev == 0) && (i.type=='M' || i.type == 'S') && strcmp(filename, fpath{1})
            %Special case -- MATLAB says that the file name takes precedence
            %over the function name, but the function name is what mlint
            %reads out. Also, subfunctions.
            j = j + 1;
        elseif (j == lev) && (i.type == 'N' || i.type == 'M') && (strcmp(i.name, fpath{j+1}))
            %we found the calling function or a parent, we're one step
            %closer
            j = j + 1;
        end
    else
        %collect all nested functions defined at this level
        %the next line tells where the function def. ends
        if (lev == j - 1) && (i.type == 'E')
            lineuntil = i.line;
        elseif (lev == j) && (i.type == 'N')
            nested{end+1} = i.name;
        elseif (i.line > lineuntil) && (lev < j)
            %we've walked out of the calling function's definition and are done
            break;
        end
    end
end