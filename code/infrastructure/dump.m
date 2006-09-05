function dump(obj, printer)
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
prefix = inputname(1);

dumpit(prefix, obj)



    function dumpit(prefix, obj)

        if ndims(obj) > 3
            error('dump:multiDimensional', 'could not dump multidimensional array.');
        end

        if isnumeric(obj)
            printer('%s = %s;', prefix, mat2str(obj))
            return;
        end

        switch class(obj)
            case 'char'
                dumpstr(prefix, obj);
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
            otherwise
                if isa(obj, 'Object')
                    dumpobject(prefix, obj.property__);
                    printer('%s = %s(%s);', prefix, obj.version__.function, prefix);
                elseif isa(obj, 'PropertyObject')
                    dumpstruct(prefix, obj);
                    printer('%s = %s(%s);', prefix, class(obj), prefix);
                else
                    error('can''t dump class %s', class(obj));
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

end