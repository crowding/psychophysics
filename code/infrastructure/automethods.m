function this = automethods();

%we grab all functions from the caller...

%Which function are we being called from? Grab the complete nested path off
%of the stack.
[st, i] = dbstack('-completenames');
fpath = splitstr('/', st(2).name);

%Use mlint to parse the m-file and print a list of all functions. (evalc it
%to capture the printout.)
filepath = st(2).file;
[tmp, filename, tmp, tmp] = fileparts(filepath);
a = @()mlint(filename, '-calls');
funs = splitstr(sprintf('\n'), evalc('a()'));

%parse the function call list into structs
funinfo = regexp(funs, '(?<type>[MENU])(?<level>\d+)\s+(?<line>\d+)\s+(?<unknown>\d+)\s+(?<name>[\w/]+)', 'names');

%We will collect method names here
methodNames = {};

%We scan for nested functions that are defined within the calling function
j = 0;
lineuntil = 0;
for i = [funinfo{:}]
    lev = str2num(i.level);
    
    if j < numel(fpath)
        %Walking into where the calling function is defined in the file...
        if (j == 0) && (lev == 0) && (i.type=='M') && strcmp(filename, fpath{1})
            %Special case -- MATLAB says that the file name takes precedence
            %over the function name, but the function name is what mlint
            %reads out.
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
            lineuntil = str2num(i.line);
        elseif (lev == j) && (i.type == 'N')
            methodNames{end+1} = i.name;
        elseif (str2num(i.line) > lineuntil) && (lev < j)
            %we've walked out of the calling function's definition and are done
            break;
        end
    end
end

%Now we have the method names.
%Exclude any method that ends in an underscore (those are private)
methodNames = methodNames(~cellfun('prodofsize', regexp(methodNames, '_$', 'start')));
%double it for struct

%Capture handles to the enclosed methods as a struct (including version
%information). Here I build the string to evaluate in the caller:
evalargs = cellfun...
    ( @(x)sprintf('''''%s'''', @%s, ', x, x)...
    , methodNames, 'UniformOutput', 0 ...
    );
evalargs = cat(2, evalargs{:});

evalstr = ['eval(''@(getversion__) struct(' evalargs ' ''''version__'''', getversion__(1))'')'];
%It returns a function which I invoke to get the struct.
structmaker = evalin('caller', evalstr);
struct = structmaker(@getversion);

%Finally make it into an object
this = publicize(struct);

end