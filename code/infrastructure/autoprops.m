function this = autoprops(varargin)
    %create final property methods based on the variables declared in the
    %calling function. Assumes the accessor methods are written.
    %If named arguments are given, assempts to set them.
    
    %grab the calling function's declared variables sneakily
    f = functions(evalin('caller', '@(v) eval(v)'));
    prop_names = fieldnames(f.workspace{2});
    
    %This give us the variable names. Matlab only gives up variable names
    %if they are used before the 
    prop_names = prop_names(~cellfun('prodofsize', regexp(prop_names, '(^varargin|_)$', 'start')));
    getter_names = cellfun(@getterName, prop_names, 'UniformOutput', 0);
    setter_names = cellfun(@setterName, prop_names, 'UniformOutput', 0);
    
    %create the getters...
    getters = cell(size(getter_names));
    setters = cell(size(getter_names));
    for ii = cat(1, prop_names(:)', num2cell(1:length(prop_names)))
        [prop_name, i] = ii{:};
        getters{i} = evalin('caller', ['@()eval(''' prop_name ''')']);
        setters{i} = evalin('caller', ['@(v) eval(''' prop_name ' = v;'')']);
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

    this = publicize(this);
    
    %now do some assignment.
    init = namedargs(varargin{:});
    for i = fieldnames(init)'
        property__(i{:}, init.(i{:}));
    end
end