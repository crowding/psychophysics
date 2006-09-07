function dump(obj, printer, prefix)
%I was going to save all my data in matlab files, but this meant that
%i would have to do all my analysis in matlab, or some matlab-compatible
%thing. Since i have grown to dislike matlab and with the long-term goal
%of banishing it it, I decided to output to plain text files instead. This
%has the added benefit that neat functional programming tricks can be done
%when reading a file back in data analysis (e.g. substitute an analysis
%function for the constructor in the right context, and analysis is as
%simple as reading and evaluating all lines.)
%
%
%
%dumps the object out using the printer (a handle to a sprintf()-like
%function.) The idea is that rumin eval() on all the strings should
%recreate the data (for objects, this presupposes that the object's nature
%is determined by its properties.)
if ~exist('prefix', 'var')
    prefix = inputname(1);
    if isempty(prefix)
        prefix = 'ans';
    end
end

if ~exist('printer', 'var') || isempty(printer)
    printer = @printtobase;
end

dumpit(prefix, obj);

    function dumpit(prefix, obj)


        if isnumeric(obj)
            if ndims(obj) > 3
                error('dump:multiDimensional', 'could not dump multidimensional array.');
            end
            printer('%s = %s;', prefix, mat2str(obj))
            return;
        end

        if ischar(obj)
            dumpstr(prefix, obj);
            return;
        end
        
        if islogical(obj)
            if ndims(obj) > 3
                error('dump:multiDimensional', 'could not dump multidimensional array.');
            end
            
            printer('%s = logical(%s)', prefix, mat2str(logical(obj)));
        end

        if numel(obj) ~= 1
            %it's not char and not numeric and not a cell, this
            %means it's complicated and we should dump individual
            %entries.
            switch class(obj)
                case 'cell'
                    dumpcell(prefix, obj)
                otherwise
                    dumpcell(prefix, num2cell(obj))
                    printer('%s = cell2mat(%s);', prefix, prefix);
            end
            return;
        end

        switch class(obj)
            case 'struct'

                if isfield(obj, 'property__')
                    dumpobject(prefix, obj.property__);
                    %we should have a field naming the constructor to
                    %call. But it could just be a bare properties thing.
                    if isfield(obj, 'version__')
                        printer('%s = %s(%s);', prefix, obj.version__.function, prefix);
                    else
                        printer('%s = properties(%s);', prefix, prefix);
                    end
                else
                    dumpstruct(prefix, obj);
                end
%{
            case 'function_handle'
                f = functions(obj);
                dumpstruct(prefix, f);
                printer('%s = undumpable(''function_handle'', %s);', prefix, prefix);
%}
            otherwise
                if isa(obj, 'Object')
                    %w = wrapped__(obj);
                    %dumpit(prefix, w);
                    %printer('%s = Object(%s);', prefix, prefix);
                    
                    v = version__(obj);
                    dumpobject(prefix, obj.property__);
                    printer('%s = %s(%s);', prefix, v.function, prefix);
                elseif isa(obj, 'PropertyObject')
                    dumpstruct(prefix, obj);
                    printer('%s = %s(%s);', prefix, class(obj), prefix);
                else
                    %we use a 
                    printer('%s = undumpable(''%s'');', prefix, class(obj));
                    %error('can''t dump class %s', class(obj));
                end
        end
    end

    function dumpstr(prefix, str)
        %i'm going to write the string as an argument to sprintf, not
        %as a matlab string, because the matlab string literals can't
        %actually escape characters, for fuck's sake.
        if size(str, 1) > 1
            error('dump:multiline', 'Can''t dump multiline strings');
        end

        if any(str == 0) || any(str > 255)
            error('dump:charValues', ...
                'can''t handle strings with nulls or high char values.')
        end

        %format the string as an argument to sprintf:

        %QUAD quotes, percents and backslashes:
        str = regexprep(str, '[''%\\]', '$0$0$0$0');

        %non-printables and high bytes get the escaped hex treatment, which
        %we obtain by a round of sprintf-ing
        i = (str < 32) | (str > 126);
        arg = regexprep(str, '[^\x20-\xFE]', '\\\\x%02x');
        str = sprintf(arg, str(i));

        %now we have escaped hex values, and double quotes, backslashes,
        %and percents, which is perfect to feed into sprintf on the input
        %side, by simply eval()ing this string:

        printer('%s = sprintf(''%s'');', prefix, str);
    end

    function dumpobject(prefix, propmethod)
        for p = propmethod()'
            %random debugging not: matlab will not how you teh difference
            %in disp() between a char array and a singleton cell containing
            %a char array, even though the distinction ALWAYS MATTERS.
            dumpit([prefix '.' p{:}], propmethod(p{:}));
        end
    end

    function dumpstruct(prefix, obj)
        for f = fieldnames(obj)'
            dumpit([prefix '.' f{:}], obj.(f{:}));
        end
    end

    function dumpcell(prefix, obj)
        nd = ndims(obj);

        sizestring = join(',', arrayfun(@num2str, size(obj), 'UniformOutput', 0));
        printer('%s = cell(%s);', prefix, sizestring);

        for i = 1:numel(obj) %go backwards to auto-size
            [sub{1:nd}] = ind2sub(size(obj), i);
            subscript = cellfun(@int2str, sub, 'UniformOutput', 0);

            subscript = ['{' join(',', subscript), '}'];
            dumpit([prefix subscript], obj{sub{:}});
        end
    end

    function printtobase(varargin)
        expr = sprintf(varargin{:});
        disp(expr);
        evalin('base', expr);
    end
end

