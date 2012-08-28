%if this doesn't optimize enough we can try accumulating into a linklist
%and only staging one write.

function dumptofile(prefix, obj, fhandle)
    if isnumeric(obj) || islogical(obj)
        if ~isreal(obj)
            error('dump:complex', 'complex not supported as of now.');
        end

        if ndims(obj) >= 3
            %iterate the slices of the array downward.
            s = size(obj); s([1 2]) = [];
            nd = length(s);
            for i = prod(s):-1:1
                [sub{1:nd}] = ind2sub(s, i);
                subscript = cellfun(@int2str, sub, 'UniformOutput', 0);
                subscript = ['(:,:,' join(',', subscript), ')'];
                dumpnumslice([prefix subscript], obj(:,:,i), fhandle);
            end
            f('%s[:,:,%s]');
        else
            dumpnumslice(prefix, obj, fhandle);
        end
        
        return;
    end
    
    if ischar(obj)
        dumpstr(prefix, obj, fhandle);
        return;
    end

    if numel(obj) ~= 1
        %it's not char and not numeric and not logical, this
        %means it's complicated and we should dump individual
        %entries.
        switch class(obj)
            case 'cell'
                dumpcell(prefix, obj, fhandle)
            otherwise
                dumpcell(prefix, num2cell(obj), fhandle)
                fprintf(fhandle, '%s = cell2mat(%s);\n', prefix, prefix);
        end
        return;
    end

    switch class(obj)
        case 'struct'
            if isfield(obj, 'property__')
                [names, st] = obj.property__();                
                
                %dumpobject(prefix, obj.property__, fhandle);
                %we should have a field naming the constructor to
                %call. But it could just be a bare properties thing.
                dumpstruct(prefix, st, fhandle);
                if isfield(obj, 'version__')
                    dumpstruct([prefix '.version__'], obj.version__, fhandle);
                    fprintf(fhandle, '%s = %s(%s);\n', prefix, obj.version__.function, prefix);
                else
                    fprintf(fhandle, '%s = objProperties(%s);\n', prefix, prefix);
                end
            else
                dumpstruct(prefix, obj, fhandle);
            end
    %{
        case 'function_handle'
            f = functions(obj);
            dumpstruct(prefix, f);
            fprintf(fhandle, '%s = undumpable(''function_handle'', %s);\n', prefix, prefix);
    %}
        case 'cell'
            dumpcell(prefix, obj, fhandle);
        otherwise
            if isa(obj, 'Object')
                %w = wrapped__(obj);
                %dumptofile(prefix, w);
                %fprintf(fhandle, '%s = Object(%s);\n', prefix, prefix);

                v = version__(obj);
                dumpobject(prefix, obj.property__, fhandle);
                dumpstruct([prefix '.version__'], v, fhandle);

                fprintf(fhandle, '%s = %s(%s);\n', prefix, v.function, prefix);
            elseif isa(obj, 'PropertyObject')
                dumpstruct(prefix, obj, fhandle);
                fprintf(fhandle, '%s = %s(%s);\n', prefix, class(obj), prefix);
            else
                fprintf(fhandle, '%s = undumpable(''%s'');\n', prefix, class(obj));
                %error('can''t dump class %s', class(obj));
            end
    end
end

function dumpnumslice(prefix, slice, fhandle)
    if isa(slice, 'double')
        fprintf(fhandle, '%s = %s;\n', prefix, smallmat2str(slice));
    else
        fprintf(fhandle, '%s = %s;\n', prefix, smallmat2str(slice, 'class'));
    end
end


function dumpstr(prefix, str, fhandle)
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

    fprintf(fhandle, '%s = sprintf(''%s'');\n', prefix, str);
end

function dumpobject(prefix, propmethod, fhandle)
    props = propmethod();
    for p = props(:)'
        %random debugging note: matlab will not show you the difference
        %in disp() between a char array and a singleton cell containing
        %a char array, even though the distinction ALWAYS MATTERS.
        dumptofile([prefix '.' p{:}], propmethod(p{:}), fhandle);
    end
end

function dumpstruct(prefix, obj, fhandle)
    for f = fieldnames(obj)'
        dumptofile([prefix '.' f{:}], obj.(f{:}), fhandle);
    end
end

function dumpcell(prefix, obj, fhandle)
    nd = ndims(obj);

    sizestring = join(',', arrayfun(@num2str, size(obj), 'UniformOutput', 0));
    fprintf(fhandle, '%s = cell(%s);\n', prefix, sizestring);

    for i = 1:numel(obj)
        [sub{1:nd}] = ind2sub(size(obj), i);
        subscript = cellfun(@int2str, sub, 'UniformOutput', 0);

        subscript = ['{' join(',', subscript), '}'];
        dumptofile([prefix subscript], obj{sub{:}}, fhandle);
    end
end