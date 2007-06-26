function this = autoprops(varargin)
    %create final property methods based on the variables declared in the
    %calling function. Assumes the accessor methods are written.
    %If named arguments are given, assempts to set them.
    S = Subscripter();
    
    %grab the calling function's declared variables
    prop_names = evalin('caller', 'whos()');
    %use only variables in the top level of nesting
    prop_names = prop_names(capture([S{prop_names.nesting}.level]) == max(capture));
    %and only variables that have been defined
    prop_names = {prop_names(cat(2, S{prop_names.class}(1)) ~= '(').name}; 
    %and not varargin or ans or anything ending with an underscore
    prop_names = prop_names(~cellfun('prodofsize', regexp(prop_names, '(^varargin|^ans|_)$', 'once', 'start')));
    
    getter_names = cellfun(@getterName, prop_names, 'UniformOutput', 0);
    setter_names = cellfun(@setterName, prop_names, 'UniformOutput', 0);
    
    %create the getters and setters.
    
    if ~isempty(prop_names)
        %make a variable name that doesn't conflict
        uniquename1 = [prop_names{end} 'a'];
        uniquename2 = [prop_names{end} 'b'];

        getterstring = sprintf('@()eval(''%s;''), ', prop_names{:});
        setterstring = sprintf(['@(' uniquename1 ') eval(''%s = ' uniquename1 ';''), '], prop_names{:});

        [getters, setters, propget, propset] = dealcell(evalin('caller', [...
            '{{' getterstring '},{' setterstring '}, ' ... 
            '@(' uniquename1 ') eval([' uniquename1 ' '';'']), ' ...
            '@(' uniquename1 ',' uniquename2 ')eval([' uniquename1 ' ''=' uniquename2 ';''])}']));
    else
        getters = {};
        setters = {};
        propget = [];
        propset = [];
    end

    arglist = cat(2, getter_names(:), getters(:), setter_names(:), setters(:))';
    this = struct(arglist{:}, 'property__', makeproperty(prop_names, propget, propset), 'method__', @noop, 'version__', getversion(2));
    this = publicize(this);
    
    %now do some assignment.
    init = namedargs(varargin{:});
    for i = fieldnames(init)'
        propset(i{:}, init.(i{:}));
    end
end