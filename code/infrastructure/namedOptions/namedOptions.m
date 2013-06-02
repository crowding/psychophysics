function opts = namedOptions(varargin)
%function opts = namedOptions(varargin)
%A utility function to handle named optional arguments in your
%functions.
%
%Example use: Suppose you are writing myFunction to take some optional
%arguments, 'origin', 'rate', and some fit options as used by the
%optimization toolbox.
%
%function myFunction(varargin)
%   %default options
%   options = struct...
%       ('origin', [1 1]...
%       , 'rate', 1.5 ...
%       , 'fitoptions', optimset() ...
%       );
%
%   %[function body...]
%end
%
%Then myFunction can be invoked with optional arguments which will
%replace the defaults, like:
%myFunction('rate', 2);
%myFunction('origin', [2 3]);
%
%You can also drill deeper into a complicated options structure, like
%this:
%
%>> myFunction('origin(2)', 5, 'rate', 3);
%>> myFunction('fitoptions.Diagnostics', 'on')
%
% Structures can be passed as well; each field in a passed structure will
% be treated as a separate named argument.
%
%>> myFunction(struct('origin', [3 2]));
%
%Instead of quoted strings, you can also use a Genitive object to produce
%subscripts. This can be somewhat faster.
%
%>> its = Genitive;
%>> myFunction('origin', [2 3]);
%>> myFunction(its.origin(2), 5, its.rate, 3);
%>> myFunction(its.fitoptions.Diagnostics, 'on');
%
%In either case it is not possible to use the special keyword END.
%
%STRICTNESS:
%
%By default, if a structure is given as the first argument, is treated as a
%template, and namedOptions will only let you set options that are already
%present in that template. You can override this behavior by giving the
%first argument as a structure with no fields . This will disable strict
%checking so that you can set any part of the options structure that can
%be indexed.
%
%For example:
%
%>> options = struct('mean', 1);
%>> namedargs(options, 'mean', 2, 'stdev', 1);
%
%will return an error, but the following will return a structure:
%
%namedargs(struct(), struct('mean', 1), 'mean', 2, 'stdev', 1)
%----
%Peter Meilstrup

    strict = 0;

    opts = struct();
    persistent its;
    if isempty(its)
        its = Genitive();
    end

    argix = 1;
    while argix <= numel(varargin)
        if isstruct(varargin{argix})
            %it can be a substruct or a regular field.
            %check if it's a valid substruct
            if isequal(fieldnames(varargin{argix}), {'type';'subs'})
                if strict
                    %check if user is allowed to give this option
                    try
                        subsref(opts, varargin{argix});
                    catch
                        error...
                            ( 'namedOptions:unknownOption'...
                            , 'Option not present in options structure: %s.'...
                            , substruct2str(varargin{argix}) );
                    end
                end

                %now try to assign the value
                if numel(varargin) == argix
                    error...
                        ( 'namedOptions:valueMissing'...
                        , 'Value missing from name/vaue pair, name was %s'...
                        , substruct2str(varargin{argix}));
                end

                try
                    %oops, here MATLAB is stupid and we have run into a
                    %problem with FUCKED DISPATCH (in which we assign to a
                    %struct a value that has a subsasgn method, invoking
                    %the wrong method entirely...)
                    opts = subsasgn(opts, varargin{argix}, varargin{argix+1});
                    argix = argix + 2;
                catch
                    error...
                        ('namedOptions:couldNotAssign'...
                        , 'Could not assign argument named %s'...
                        , substruct2str(varargin{argix}));
                end

            else
                %Not a substruct, so treat it as a regular struct (i.e.
                %expand it)

                %special case, for the first argument: it gets transferred
                %directly, and we then go into strict mode.
                if argix == 1
                    opts = varargin{1};
                    argix = argix+1;
                    if ~isempty(fieldnames(varargin{1}));
                        strict = 1;
                    end
                    continue;
                end

                fnames = fieldnames(varargin{argix});
                f = num2cell(struct('type', '.', 'subs', fnames(:)'));
                g = struct2cell(varargin{argix});
                replacement = {f{:};g{:}};
                varargin = {varargin{1:argix-1} replacement{:} varargin{argix+1:end}};
                continue;
            end

        elseif ischar(varargin{argix})
            if isvarname(varargin{argix})
                varargin{argix} = struct('type', '.', 'subs', varargin{argix});
            else
                %could be a more complicated subscript
                varargin{argix} = str2substruct(varargin{argix});
            end
        else
            error...
                ( 'namedOptions:badName'...
                , 'expected a string, subscript or structure (got %s)'...
                , strcat(evalc('display(varargin(argix))')) );
        end
    end
end

function x = substruct2str(subs)
    %a diagnostic function for the error messages, which cooks a substruct
    %back into a string (hopefully)
    try
        for i = numel(subs):-1:1
            if numel(subs(i).type) == 1
                x{i} = ['.' subs(i).subs];
            else
                x{i} = [subs(i).type(1) join(',', cellfun(@sub, subs(i).subs(:)', 'UniformOutput', 0)) subs(i).type(2)];
            end
        end

        x = [x{:}];
    catch
        x = 'couldn''t convert substruct!';
    end
end

function x = str2substruct(str)
    persistent its;
    if isempty(its)
        its = Genitive();
    end
    try
        x = eval(sprintf('(its.%s);', str));
    catch
        error('namedOptions:badString', 'Can''t interpret subscript string: %s', str)
    end
end

function x = sub(s)
    switch class(s)
        case 'char'
            x = s; %field names, ':', etc.
        otherwise
            x = mat2str(s, 1);
    end
end