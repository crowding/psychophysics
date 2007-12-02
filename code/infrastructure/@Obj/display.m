function display(this)
    if isstruct(this.wrapped) && isfield(this.wrapped, 'version__') && ~isempty(this.wrapped)
        prefix = inputname(1);
        if ~isempty(prefix)
            prefix = [prefix ' = '];
        end
        switch numel(this)
            case 1
                disp([prefix this.wrapped.version__.function ':']);
                [property, st] = this.wrapped.property__();
                disp(st);
                
                %Format the methods for the command window size
                s = get(0, 'CommandWindowSize');
                introstr = 'Methods: ';
                
                getn = cellfun(@getterName, property, 'UniformOutput', 0);
                setn = cellfun(@setterName, property, 'UniformOutput', 0);
                
                %hide what methods are accessors?
                methods = this.wrapped.method__();
                methods = setdiff(methods, {getn{:}, setn{:}});
                methodstr = WrapString(join(', ', methods), s(1) - numel(introstr));
                
                introstr(size(methods, 1), end) = ' ';
                disp([introstr methodstr]);
            otherwise
                disp(sprintf([prefix '[%s %s]'] ...
                    , join('x', cellstr(num2str(size(this)', '%g')))...
                    , this.wrapped(1).version__.function));
        end
    else
        disp(this.wrapped);
    end
end