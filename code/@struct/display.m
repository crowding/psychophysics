%DISP
%
%display method for structs accounting for auto-objects.

function display(this)
    if isfield(this, 'method__') && ~isempty(this)
        prefix = inputname(1);
        if ~isempty(prefix)
            prefix = [prefix ' = '];
        end
        switch numel(this)
            case 1
                disp([prefix this.version__.function ':']);
                [property, st] = this.property__();
                disp(st);

                %Format the methods for the command window size
                s = get(0, 'CommandWindowSize');
                introstr = 'Methods: ';

                getn = cellfun(@getterName, property, 'UniformOutput', 0);
                setn = cellfun(@setterName, property, 'UniformOutput', 0);

                %hide what methods are accessors?
                methods = this.method__();
                methods = setdiff(methods, {getn{:}, setn{:}});
                methodstr = WrapString(join(', ', methods), s(1) - numel(introstr));

                introstr(size(methodstr, 1), end) = ' ';
                disp([introstr,methodstr]);
            otherwise
                disp(sprintf([prefix '[%s %s]'] ...
                    , join('x', cellstr(num2str(size(this)', '%g')))...
                    , this.version__.function));
        end
    else
        %this doesn't preserve the input name... structs all get displayed
        %as 'this = ...'
        %builtin('display', this);
        
        %well, this is one way to preserve the input name while calling the
        %builting struct display...
        evalin('caller', ['builtin(''display'',' inputname(1) ')']);
    end
end