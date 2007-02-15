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
        printer = @printf;
    end

    dumpit(prefix, obj, printer);

end

function dumpit(prefix, obj, printer)

    if isnumeric(obj)
        if ndims(obj) > 3
            error('dump:multiDimensional', 'could not dump multidimensional array.');
        end
        if isa(obj, 'double')
            printer('%s = %s;', prefix, smallmat2str(obj));
        else
            printer('%s = %s;', prefix, smallmat2str(obj, 'class'));
        end
        return;
    end

    if ischar(obj)
        dumpstr(prefix, obj, printer);
        return;
    end

    if islogical(obj)
        if ndims(obj) > 3
            error('dump:multiDimensional', 'could not dump multidimensional array.');
        end

        printer('%s = logical(%s);', prefix, smallmat2str(double(obj)));
        return;
    end

    if numel(obj) ~= 1
        %it's not char and not numeric and not logical, this
        %means it's complicated and we should dump individual
        %entries.
        switch class(obj)
            case 'cell'
                dumpcell(prefix, obj, printer)
            otherwise
                dumpcell(prefix, num2cell(obj), printer)
                printer('%s = cell2mat(%s);', prefix, prefix);
        end
        return;
    end

    switch class(obj)
        case 'struct'

            if isfield(obj, 'property__')
                dumpobject(prefix, obj.property__, printer);
                %we should have a field naming the constructor to
                %call. But it could just be a bare properties thing.
                if isfield(obj, 'version__')
                    dumpstruct([prefix '.version__'], obj.version__, printer);
                    printer('%s = %s(%s);', prefix, obj.version__.function, prefix);
                else
                    printer('%s = properties(%s);', prefix, prefix);
                end
            else
                dumpstruct(prefix, obj, printer);
            end
    %{
        case 'function_handle'
            f = functions(obj);
            dumpstruct(prefix, f);
            printer('%s = undumpable(''function_handle'', %s);', prefix, prefix);
    %}
        case 'cell'
            dumpcell(prefix, obj, printer);
        otherwise
            if isa(obj, 'Object')
                %w = wrapped__(obj);
                %dumpit(prefix, w);
                %printer('%s = Object(%s);', prefix, prefix);

                v = version__(obj);
                dumpobject(prefix, obj.property__, printer);
                dumpstruct([prefix '.version__'], v, printer);

                printer('%s = %s(%s);', prefix, v.function, prefix);
            elseif isa(obj, 'PropertyObject')
                dumpstruct(prefix, obj, printer);
                printer('%s = %s(%s);', prefix, class(obj), prefix);
            else
                printer('%s = undumpable(''%s'');', prefix, class(obj));
                %error('can''t dump class %s', class(obj));
            end
    end
end

function dumpstr(prefix, str, printer)
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

function dumpobject(prefix, propmethod, printer)
    for p = propmethod()'
        %random debugging note: matlab will not how you the difference
        %in disp() between a char array and a singleton cell containing
        %a char array, even though the distinction ALWAYS MATTERS.
        dumpit([prefix '.' p{:}], propmethod(p{:}), printer);
    end
end

function dumpstruct(prefix, obj, printer)
    for f = fieldnames(obj)'
        dumpit([prefix '.' f{:}], obj.(f{:}), printer);
    end
end

function dumpcell(prefix, obj, printer)
    nd = ndims(obj);

    sizestring = join(',', arrayfun(@num2str, size(obj), 'UniformOutput', 0));
    printer('%s = cell(%s);', prefix, sizestring);

    for i = 1:numel(obj)
        [sub{1:nd}] = ind2sub(size(obj), i);
        subscript = cellfun(@int2str, sub, 'UniformOutput', 0);

        subscript = ['{' join(',', subscript), '}'];
        dumpit([prefix subscript], obj{sub{:}}, printer);
    end
end