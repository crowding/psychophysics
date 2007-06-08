function this = autoprops(varargin)
    %create final property methods based on the variables declared in the
    %calling function. Assumes the accessor methods are written.
    %If named arguments are given, assempts to set them.
    
    %grab the calling function's declared variables sneakily
    f = functions(evalin('caller', '@() eval(''0'')'));
    prop_names = fieldnames(f.workspace{2});
    
    %this give us the variable names. THe ones ending with underscore are
    %the properties we want.
    prop_names = regexp(prop_names, '(.*)_$', 'tokens');
    prop_names = cat(1, {}, prop_names{:});
    prop_names = cat(1, {}, prop_names{:});
    getter_names = cellfun(@getterName, prop_names, 'UniformOutput', 0);
    setter_names = cellfun(@setterName, prop_names, 'UniformOutput', 0);
    
    %create the getters...
    getters = cell(size(getter_names));
    setters = cell(size(getter_names));
    for ii = cat(1, prop_names(:)', num2cell(1:length(prop_names)))
        [prop_name, i] = ii{:};
        var_name = [prop_name '_'];
        acc = evalin('caller', '@()0');
        subs = substruct('.', 'workspace', '{}', {2}, '.', prop_name);
        getters{i} = @()subsref(functions(acc), subs);
        setters{i} = evalin('caller', ['@(v) eval(''' var_name ' = v;'')']);
    end
        
    arglist = cat(2, getter_names(:), getters(:), setter_names(:), setters(:))';
    this = struct(arglist{:}, 'property__', @property__, 'method__', @method__, 'version__', getversion(2));

    function value = property__(name, value)
        switch nargin
            case 0
                value = prop_names;
            case 1
                %could this be made more efficient?
                value = this.(getterName(name))();
            otherwise
                this.(setterName(name))(value);
        end
    end

    %this only exists to be used by publicize....
    function value = method__(name, value)
        switch nargin
            case 0
                value = {getter_names{:}, setter_names{:}}';
            case 1
                value = this.(name);
            otherwise
                error('autoprops:cannotModify', 'cannot override auto-prop methods?');
        end
    end
    
    %now do some assignment.
    init = namedargs(varargin{:});
    for i = fieldnames(init)'
        property__(i{:}, init.(i{:}));
    end
end