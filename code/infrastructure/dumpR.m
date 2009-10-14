function dumpR(obj, printer, prefix)
    % function dumpR(obj, printer, prefix)
    %
    %dumps the object out using the printer (a handle to a sprintf()-like
    %function.) The idea is that running eval() on all the strings should
    %recreate the data (for objects, this presupposes that the object's nature
    %is determined by its properties.)
    %
    % Example:
    %   >> printf = @(varargin) disp(sprintf(varargin{:}));     
    %   >> dump(struct('field', {{1, 2, 3}}), printf, 'name')  
    %   name.field = cell(1,3);
    %   name.field{1,1} = 1 ;
    %   name.field{1,2} = 2 ;
    %   name.field{1,3} = 3 ;
    %
    % I was going to save all my data in matlab files, but this meant that
    % i would have to do all my analysis in matlab, or some matlab-compatible
    % thing. Since i have grown to dislike matlab and with the long-term goal
    % of banishing it, I decided to output to plain text files instead. This
    % has the added benefit that neat functional programming tricks can be done
    % when reading a file back in data analysis (e.g. substitute an analysis
    % function for the constructor in the right context, and analysis is as
    % simple as reading and evaluating all lines.)
    
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
        dims = sprintf('%d,', size(obj));
        dims(end) = ')';
        
        if ~isempty(obj)
            if ~isreal(obj)
                %complex overrides integer in R numerics...
                strs = sprintf('%.15g+%.15gi,', [real(obj(:)');imag(obj(:)')]);
            elseif isinteger(obj)
                strs = sprintf('%dL,', obj);
            else
                strs = sprintf('%.15g,', obj);
            end
            strs(end) = ')';
            printer('%s <- array(c(%s,dim=c(%s);', prefix, strs, dims);
        else
            if ~isreal(obj)
                printer('%s <- array(complex(0),dim=c(%s);', prefix, dims);
            elseif isinteger(obj)
                printer('%s <- array(integer(0),dim=c(%s);', prefix, dims);
            else
                printer('%s <- array(numeric(0),dim=c(%s);', prefix, dims);
            end
        end
        return;
    end
    
    if islogical(obj)
        dims = sprintf('%d,', size(obj));
        dims(end) = ')';
        
        if ~isempty(obj)
            strs = ['F';','];
            strs = strs(:, ones(numel(obj)));
            strs(1,obj) = 'T';
            strs = strs(:)' ;
            strs(end) = ')';
            printer('%s <- array(c(%s,dim=c(%s)', prefix, strs, dims);
        else
            printer('%s <- array(logical(0),dim=c(%s)', prefix, dims);
        end
        return;
    end
    
    if ischar(obj)
        dumpstr(prefix, obj, printer);
        return;
    end

    %it's not char and not numeric and not logical, this
    %means it's complicated, either a cell, a struct, or an aray of
    %objects (horrors!)
    switch class(obj)
        case 'cell'
            dumpcell(prefix, obj, printer);
            return;
            case 'struct'
                if isfield(obj, 'property__')
                    error('dumpR:object', 'I haven''t implemented dumping for objects');
                else
                    dumpstruct(prefix, obj, printer);
                    return;
                end
        otherwise
            error('dumpR:what', 'I haven''t implemented dumping for class ''%s''', class(obj));
    end
end

function dumpstr(prefix, str, printer)
    %format the string as something that will be evaluated as the same R
    %string. Note R supports unicode too...

    %i'm going to write the string as an argument to sprintf, not
    %as a matlab string, because the matlab string literals can't
    %actually escape characters, for fuck's sake.
    if size(str, 1) > 1
        error('dump:multiline', 'Can''t dump multiline strings');
    end

    if any(str == 0)
        error('dump:charValues', ...
            'strings with nulls not supported in R.')
    end

    %format the string as an argument to sprintf:

    %first quadruple percents and backslashes:
    str = regexprep(str, '[%\\]', '$0$0$0$0');

    %non-printables and high bytes get the escaped hex treatment, which
    %we obtain by a round of sprintf-ing (eating up the doubled percents
    %and backslashes too)
    i = (str < 32) | (str > 126);
    
    chars = str(i);
    str(i) = 0;
    arg = regexprep(str, '[\x00]', '\\\\u{%02x}');
    str = sprintf(arg, chars);

    %double quotes get a single escaping
    str = regexprep(str, '"', '\\"');

    %now we have escaped hex values, and double quotes, backslashes,
    %and percents, making it good to feed to R:
    printer('%s <- "%s";', prefix, str);
end

function dumpobject(prefix, propmethod, printer)
    props = propmethod();
    for p = props(:)'
        %random debugging note: matlab will not show you the difference
        %in disp() between a char array and a singleton cell containing
        %a char array, even though the distinction ALWAYS MATTERS.
        dumpit([prefix '.' p{:}], propmethod(p{:}), printer);
    end
end

function dumpstruct(prefix, obj, printer)
    %structs in matlab correspond to lists in R with named first dimension
    fnames = fieldnames(obj);
    %replace underscore with dot in field names
    fnames = strrep(fnames, '_', '.');
    names = sprintf('"%s",', fnames{:});
    names(end) = ')';
    dimnames = sprintf('list(c(%s,%s', names, repmat('NULL,', 1, ndims(obj)));
    dimnames(end) = ')';

    s = size(obj);
    s = [numel(fnames) s];
    obj = struct2cell(obj);
    
    dims = sprintf('%d,', s);
    dims(end) = ')';

    printer('%s <- array(vector(mode="list"),dim=c(%s,dimnames=%s)', prefix, dims, dimnames);

    %if it's a singleton struct, also asign the names, with the dimnames.
    %Can't hurt to do this.
    if prod(s(2:end)) == 1
        printer('names(%s) <- c(%s;',prefix, names);
    end

    for i = 1:numel(obj)
        subscript = sprintf('[[%d]]', i);
        dumpit([prefix subscript], obj{i}, printer);
    end
end

function dumpcell(prefix, obj, printer)
    %cells in matlab correspond to lists in R.
    dims = sprintf('%d,', size(obj));
    dims(end) = ')';
    printer('%s <- array(vector(mode="list"),dim=c(%s)', prefix, dims);

    for i = 1:numel(obj)
        subscript = sprintf('[[%d]]', i);
        dumpit([prefix subscript], obj{i}, printer);
    end
end