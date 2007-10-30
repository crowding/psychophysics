function this = autoobject(varargin)
    %combines the duties of autoprops and automethods into one faster
    %function (no trip through finalize necessary.)
    
    %For speed I want to minimize the number of lexical scope variables that
    %property__ and method__ carry around. Thus the subfunction and the
    %one-liner-ism here, as well as the recycling of variable names :-/
    
    %VERY FUCKING SNEAKY HERE! MATLAB's restriction on adding variables to
    %a static workspace apparently does not extend to persistent variables.
    %Therefore if we want to cache a value with a calling function and have
    %it associated with the function (and cleared whenever the function is
    %recompiled) we can just stuff it in a persistent variable using
    %evalin!
    evalin('caller', 'persistent init__;');
    this = evalin('caller', 'init__;');
    
    if isempty(this)
        [this, prop_names, method_names] = makeObjString...
            ( evalin('caller', 'whos()') ...
            , dbstack('-completenames') );
        version = getversion(2);
        tmp = evalin('caller', '@(varargin) eval(''init__ = varargin;'');');
        tmp(this, prop_names, method_names, version);
        clear tmp;
    else
        [this, prop_names, method_names, version] = this{:};
    end
    
    this = evalin('caller', this);
    this{2} = this{2}(@property__, @method__, version);
    this{1}(namedargs(varargin{:}), this{2});
    this = this{2};

    %convert prop_names into a struct for speed in property access?
  
    function value = property__(name, value)
        switch(nargin)
            case 0
                value = prop_names;
            case 1
                if any(strcmp(name, prop_names))
                    value = this.(getterName(name))();
                else
                    error('object:noSuchProperty', 'no such property %s', name);
                end
            case 2
                if any(strcmp(name, prop_names))
                    this.(setterName(name))(value);
                else
                    error('object:noSuchProperty', 'no such property %s', name);
                end
        end
    end

    function method = method__(name, value)
        switch(nargin)
            case 0
                method = method_names;
            case 1
                method = this.(name);
            case 2
                this.(name) = value;
        end
    end
%}


            
    function prop_names = propNames(prop_names)
        S = Subscripter;
        %use only variables in the top level of nesting
        prop_names = prop_names(capture([S{prop_names.nesting}.level]) == max(capture));

        %Used to not make properties of undifined variables. But now I do.
        %prop_names = {prop_names(cat(2, S{prop_names.class}(1)) ~= '(').name}; 
        prop_names = {prop_names.name}';
        
        %TOOD: only variables that occur on lines before the call whether
        %or not they are defined.
        
        %and not varargin or ans or this or anything ending with an underscore
        prop_names = prop_names(~cellfun('prodofsize', regexp(prop_names, '(^varargin|^ans|^this|_)$', 'once', 'start')));
    end

    function names = methodNames(stack)
        names = getNestedFunctions(stack(2).file, stack(2).name);
        names = names(~cellfun('prodofsize', regexp(names, '_$', 'start')));
    end
    
    function [string, prop_names, method_names] = makeObjString(whos, stack)
        %matlab insanity: once again, it fails to do anything consistent
        %with empty arrays. cellfun() insists that
        %empty array inputs be of exactly the same size. This wouldn't be
        %too bad except that matlab's functions are incoherent. Half of
        %them return a (0,0) empty input in the case of any empty input,
        %while the other half return en empty input of the same dimensions
        %as the regular input.
        %
        %But here, setdiff() returns a
        %0-by-0 sized cell array, while its second output is 1-by-0! So not
        %only is the handlign of zero-sized arrays different between matlab
        %functions, it is also incoherent within the same function!!
        
        %Oh, for fuck's sake. Indexing does not respect the orientation of
        %an indexing argument.
        %
        %Watch this. You can index a square array with an argument, and the
        %result will respect the orientation of the indexing array.
        %
        %a = [10 20; 30 40]
        %a([1 4]) %== [10 40]
        %a([1;4]) %== [10;40]
        %
        %But try the same when a has one row:
        %
        %a = [1 2 3 4]
        %a([1 4]) = [10 40]
        %a([1;4]) = [10 40]
        %
        %Argh. So, if you have a vector you don't know the orientation of,
        %and a vector of indices, there is no way to tell the orientation
        %of the result of the indexing operation (without modifying the
        %damn thing like here.)
        
        %here, cache the file...
        
        prop_names = propNames(whos);
        prop_names = prop_names(:);
        method_names = methodNames(stack);
        method_names = method_names(:);
        
        %In ordinary programming, you handle the case 'zero', and 'one' and
        %cases of more than one generally follow. Not so matlab. You can
        %write a matlab program to handle more than one, and it will likely
        %break at one or zero.
        
        getter_names = cellfun(@getterName, prop_names, 'UniformOutput', 0);
        getters = getter_names;
        [getter_names, getteri] = setdiff(getter_names, method_names);
        setter_names = cellfun(@setterName, prop_names, 'UniformOutput', 0);
        setters = setter_names;
        [setmethod_names, setmethodi] = intersect(method_names, setter_names);
        [setter_names, setteri] = setdiff(setter_names, method_names);
        
        %assignments to the new obejct can be made directly, or by the
        %setters we are using.
 
        %to create the object, we evaluate in the caller a string built like so: 
        %setOtherVar(assignments__.otherVar) evalin('caller', '@() struct('method', @method, ..., property__, method__, version__)
        %consisting of:
        %example getter: 'getProp', @()eval('prop'), 
        %example setter: 'setProp', @(prop_)eval('prop = prop_'), 
        %example method: 'method', @method, 
        
        getterstrings = cellfun ...
            ( @(getter_name, prop_name) sprintf('''%s'', @()eval(''%s;''), ', getter_name, prop_name) ...
            , getter_names(:) ...
            , prop_names(getteri(:)) ...
            , 'UniformOutput', 0 ...
            );
        
        setterstrings = cellfun ...
            ( @(setter_name, prop_name) sprintf('''%s'', @(%s_)eval(''%s=%s_;''), ', setter_name, prop_name, prop_name, prop_name) ...
            , setter_names(:) ...
            , prop_names(setteri(:)) ...
            , 'UniformOutput', 0 ...
            );
        
        methodstrings = cellfun ...
            ( @(method_name) sprintf('''%s'', @%s, ', method_name, method_name) ...
            , method_names(:) ...
            , 'UniformOutput', 0 ...
            );

        %There is also a setter string, which needs to be evaluated
        assignmentstrings = cellfun ...
            ( @(variable_name) sprintf('if isfield(assignments__, ''''%s''''); %s = assignments__.%s; end;', variable_name, variable_name, variable_name) ...
            , prop_names(setteri(:))...
            , 'UniformOutput', 0 ...
            );
        
        settingstrings = cellfun ...
            ( @(setter_name, variable_name) sprintf('if isfield(assignments__, ''''%s''''); this__.%s(assignments__.%s); end;', variable_name, setter_name, variable_name)...
            , setmethod_names(:) ...
            , prop_names(setmethodi(:)) ...
            , 'UniformOutput', 0 ...
            );
        
        string = cat(2, '{@(assignments__, this__) eval(''', assignmentstrings{:}, settingstrings{:}, '''), @(property__, method__, version__) struct(', getterstrings{:}, setterstrings{:}, methodstrings{:}, '''property__'', property__, ''method__'', method__, ''version__'', version__)}');
        method_names = cat(1, getter_names(:), setter_names(:), method_names(:));
    end

end

    
    %WTF matlab: there's no easy way to extract more than one field of a
    %struct at a time. The best way I can come up with is
    %cellfun-dependent:

    %{
    setters = cat(1, prop_names(:)', cellfun(@(x)this.(x), setters(:)', 'UniformOutput', 0));
    setters = struct(setters{:});
	getters = cat(1, prop_names(:)', cellfun(@(x)this.(x), getters(:)', 'UniformOutput', 0));
    getters = struct(getters{:});
    function value = property__(name, value)
        switch(nargin)
            case 0
                value = prop_names;
            case 1
                if isfield(getters, name)
                    value = getters.(name)();
                else
                    error('object:noSuchProperty', 'no such property %s', name);
                end
            case 2
                if isfield(setters, name)
                    setters.(name)(value);
                else
                    error('object:noSuchProperty', 'no such property %s', name);
                end
        end
    end

    function method = method__(name, value)
        switch(nargin)
            case 0
                method = method_names;
            case 1
                method = this.(name);
            case 2
                %reverse translate method names, argh?
                %y'know, it's getting to be a drag, this getter-setter
                %distinction.
                this.(name) = value;
        end
    end
    %}
  