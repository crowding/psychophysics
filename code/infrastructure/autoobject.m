function this = autoobject(varargin)
    %Creates an object from the calling function. Each nested defines
    %a method, except for subfunctions ending in an underscore. Each
    %variable defines a property, which will have automatically generated
    %get/set methods, except for variables ending in underscores.
    %
    %Example:
    %
    %function this = increment(varargin)
    %   value = 0;
    %
    %   persistent init__;
    %   this = autoobject(varargin{:}); %makes the object.
    %
    %   function n = next()
    %       value = value + 1;
    %       n = value;
    %   end
    %end
    %
    %This function creates an object 'increment'.
    %
    %You can use it thus:
    %
    %>> i = increment('value', 14);
    %>> i.increment()
    %ans = 14
    %>> i.increment()
    %ans = 15
    %>> i.setValue(3);
    %>> i.increment()
    %ans = 4
    %
    %YOU MUST: Include the line 'persistent init__;' and you must assign the
    %output of autoobject to the variable 'this'.
    %
    %Note, persistent and global variables are treated the same way as
    %local variables! There's no way for me to tell the difference!
    
    persistent its;
    if isempty(its)
        its = Genitive();
    end

    hasInit = ~isempty(evalin('caller', 'whos(''init__'')'));
    if hasInit
        this = evalin('caller', 'init__;');
    else
        warning('autoobject:needsCache','For better speed, add the declaration ''persistent init__;'' before the call to autoobject');
        this = [];
    end
    
    if isempty(this)
        [this, prop_names, method_names] = makeObjString...
            ( evalin('caller', 'whos()') ...
            , dbstack('-completenames') );
        version = getversion(2);
        if ~isempty(tmp)
            if hasInit
                backchannel('store',{this, prop_names, method_names, version});
                evalin('caller', 'init__ = backchannel(''recall'');');
            end
            clear tmp;
            clear hasInit
        end
    else
        [this, prop_names, method_names, version] = this{:};
    end

    
    this = evalin('caller', this);
    this{2} = this{2}();
        
    tostruct = this{3};
    setmethod = this{4};
    setthis = this{5};
    this = this{2};
    
    this.property__ = @property__;
    this.method__ = @method__;
    this.version__ = version;
    
    if defaults('exists', version.function);
        property__(defaults('get', version.function));
    end
    
    if ~isempty(varargin)
        property__(varargin{:});
    end

    function varargout = property__(name, value, varargin)
        doAssignments = 0;
        switch(nargin)
            case 0
                varargout{1} = prop_names;
                if nargout > 1
                    varargout{2} = tostruct(this);
                end
            case 1
                if ischar(name)
                    if any(strcmp(name, prop_names))
                        varargout{1} = this.(getterName(name))();
                    else
                        %perhaps it is a subscript. Try that.
                        subs = subsrefize_(name);
                        [varargout{1:nargout}] = subsref_(this, subs);
                    end
                elseif isstruct(name) && isequal(fieldnames(name), {'type';'subs'})
                    %Try a substruct.
                    [varargout{1:nargout}] = subsref_(this, name);
                elseif isstruct(name)
                    %actually we are doing assignments
                    doAssignments = 1;
                    varargin = {name};
                end
            otherwise
                varargin = {name, value, varargin{:}};
                doAssignments = 1;
        end
        
        if doAssignments
            while numel(varargin) >= 1
                if ischar(varargin{1})
                    if numel(varargin) <= 1
                        error('autoobject:badArgument', 'Must use name/value pairs with property__');
                    end

                    if any(strcmp(varargin{1}, prop_names))
                        this.(setterName(varargin{1}))(varargin{2});
                        varargin([1 2]) = [];
                    else
                        
                        subs = subsrefize_(varargin{1});
                        if ischar(subs(1).subs) && any(strcmp(subs(1).subs, prop_names))
                            subsasgn_(this, subs, varargin{2});
                            varargin([1 2]) = [];
                        else
                            if ischar(subs(1).subs)
                                if (subs(1).subs(end)) == '_'
                                    %ignore
                                    varargin([1 2]) = [];
                                else
                                    error('autoobject:noSuchProperty', 'No such property %s', subs(1).subs);
                                end
                            else
                                error('autoobject:badSubscript', 'bad property__ argument ');
                            end
                        end
                    end
                elseif isstruct(varargin{1}) && isequal(fieldnames(varargin{1}), {'type';'subs'})
                    if numel(varargin) <= 1
                        error('autoobject:badArgument', 'Must use name/value pairs with property__');
                    end
                    %assigning via a substruct...
                    subsasgn_(this, varargin{1}, varargin{2});
                    varargin([1 2]) = [];
                elseif isstruct(varargin{1})
                    %special case for synthesizing an object from struct
                    %fields...
                    sargs = cat(1, fieldnames(varargin{1})', struct2cell(varargin{1})');
                    varargin = {sargs{:}, varargin{2:end}};
                else
                    error('autoobject:badArgument','bad arguments to property__');
                end
            end
        end
    end

    function varargout = subsref_(this, subs)
        %copied from @Obj
        
        %try a non-recursive algorithm.
        whatsleft = this; %the head of the data we have drilled down to so far

        for step = 1:numel(subs)-1
            property = subs(step).subs;
            if strcmp(subs(step).type, '.') && isfield(whatsleft, 'property__')
                try
                    try
                        whatsleft = whatsleft.(getterName(property))();
                    catch
                        whatsleft = whatsleft.property__(property);
                    end
                catch
                    %faster to ask forgiveness than permission...
                    if ~any(strcmp(whatsleft.property__(), property))
                        error('Obj:noSuchProperty', 'No such property %s', property);
                    else
                        rethrow(lasterror);
                    end
                end
            else
                whatsleft = subsref(whatsleft, subs(step));
            end
        end

        %last one, varargout it.
        property = subs(end).subs;
        if strcmp(subs(end).type, '.') && isfield(whatsleft, 'property__')
            try
                try
                    [varargout{1:nargout}] = whatsleft.(getterName(property))();
                catch
                    [varargout{1:nargout}] = whatsleft.property__(property);
                end
            catch
                %faster to ask forgiveness than permission...
                if ~any(strcmp(wrapped.property__(), property))
                    error('Obj:noSuchProperty', 'No such property %s', property);
                else
                    rethrow(lasterror);
                end
            end
        else
            [varargout{1:nargout}] = subsref(whatsleft, subs(end));
            %[varargout{1:nargout}] = unwrap(varargout{1:nargout});
        end
    end

    function subsasgn_(this, subs, what)
        %copied mostly from @Obj 

        %try a non-recursive algorithm.
        lowestrefobj = []; %the lowest reference object in the assignment chain
        property = [];
        belowit = []; %what data lies below in the tree
        subsleft = []; %what subscript lies below the lowest ref-obj

        whatsleft = this; %the head of the data we have drilled down to so far

        for step = 1:numel(subs) -1
            property = subs(step).subs;
            if strcmp(subs(step).type, '.') && isfield(whatsleft, 'property__')
                try
                    lowestrefobj = whatsleft;
                    try
                        belowit = whatsleft.(getterName(property))();
                    catch
                        belowit = whatsleft.property__(property);
                    end
                    subsleft = subs(step+1:end);
                    whatsleft = belowit;
                catch
                    %faster to ask forgiveness than permission...
                    if ~any(strcmp(whatsleft.property__(), subs(step).subs))
                        error('Obj:noSuchProperty', 'No such property %s', subs(step).subs);
                    else
                        rethrow(lasterror);
                    end
                end
            else
                whatsleft = subsref(whatsleft, subs(step));
            end
        end

        %now we are up to all but the last assignment; what is it?

        if strcmp(subs(end).type, '.') && isfield(whatsleft, 'property__')
            %the last assignment is ultimately a reference object assignment.
            %Whew. Just make the assignment!
            try
                try
                    whatsleft.(setterName(subs(end).subs))(what);
                catch
                    whatsleft.property__(subs(end).subs, what);
                end
            catch
                %faster to ask forgiveness than permission...
                if ~any(strcmp(whatsleft.property__(), subs(end).subs))
                    error('Obj:noSuchProperty', 'No such property %s', subs(end).subs);
                else
                    rethrow(lasterror);
                end
            end
        else
            if ~isempty(lowestrefobj)
                %we assign under the lowest reference object!
                newval = subsasgn(belowit, subsleft, what);
                %and update the value in teh reference object
                try
                    try
                        lowestrefobj.(setterName(property))(newval);
                    catch
                        lowestrefobj.property__(property, newval);
                    end
                catch
                    %faster to ask forgiveness than permission...
                    if ~any(strcmp(lowestrefobj.property__(), property))
                        error('Obj:noSuchProperty', 'No such property %s', subs(1).subs);
                    else
                        rethrow(lasterror);
                    end
                end
            else
                %well hey. since no reference objects are involved, we complete
                %the assignment by normal means.
                whatsleft = subsasgn(whatsleft, subs, what); %but this shouldn't happen!
            end
        end
    end

    function subs = subsrefize_(subs)
        if ischar(subs)
            %convert to a substruct...
            try
                subs = eval(sprintf('(its.%s);', subs));
            catch
                errorcause(lasterror, 'Randomizer:invalidSubscript', 'Invalid subscript reference ".%s"', subs);
            end
        end

        %check that you actually have a substruct
        try
            subs = subsref(its, subs);
        catch
            errorcause(lasterror, 'Randomizer:invalidSubscript', 'Improper substruct');
        end
    end

    function [method, canonical, parents] = method__(name, value)
        switch(nargin)
            case 0
                method = method_names;
                canonical = this;
                parents = {};
            case 1
                if isstruct(name)
                    %reasigning 'this' wholesale
                    setthis(name);
                    this = name;
                else
                    method = this.(name);
                end
            case 2
                method_names = union(method_names, name);
                this.(name) = value;
                setmethod(name, value);
        end
    end
            
    function prop_names = propNames(prop_names)
        %use only variables in the top level of nesting
        tmp = [prop_names.nesting];
        prop_names = prop_names([tmp.level] == max([tmp.level]));

        prop_names = {prop_names.name}';
        
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
        %But here, setdiff()'s first output returns a
        %0-by-0 sized cell array, while its second output is 1-by-0! So not
        %only is the handling of zero-sized arrays different between matlab
        %functions, it is also incoherent within the same function!!
        
        %Oh, and: for fuck's sake. Indexing does not respect the
        %orientation of an indexing argument.
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
        %a([1 4]) %== [10 40]
        %a([1;4]) %== [10 40]
        %
        %Argh. So, if you have a vector you don't know the orientation of,
        %and a vector of indices, there is no way to tell the orientation
        %of the result of the indexing operation, hence no way to use it in
        %an expression without saving it to a damn temp variable and salting
        %it with (:).
        
        %here, cache the file...
        
        prop_names = propNames(whos);
        prop_names = prop_names(:);
        method_names = methodNames(stack);
        method_names = method_names(:);
        
        %In ordinary programming, you handle the case 'zero', and 'one' and
        %cases of more than one generally follow. Not so matlab. You can
        %write a matlab program to handle more than one, and it will likely
        %break at one or zero.
        
        %Figure out which getters/setters to synthesize and which
        %get/set methods to call as provided
        
        getter_names = cellfun(@getterName, prop_names, 'UniformOutput', 0);
        [getmethod_names, getmethodi] = intersect(getter_names, method_names);
        [getter_names, getteri] = setdiff(getter_names, method_names);
        setter_names = cellfun(@setterName, prop_names, 'UniformOutput', 0);
        [setmethod_names, setmethodi] = intersect(setter_names, method_names);
        [setter_names, setteri] = setdiff(setter_names, method_names);
            
        %assignments to the new object can be made directly, or by the
        %setters we are using.
 
        %to create the object, we evaluate in the caller a string built like so: 
        %setOtherVar(assignments__.otherVar) evalin('caller', '@() struct('method', @method, ..., property__, method__, version__)
        %consisting of:
        %example getter: 'getProp', @()eval('(prop);'), 
        %example setter: 'setProp', @(prop_)eval('prop = prop_;'), 
        %example method: 'method', @method, 
        
        getterstrings = cellfun ...
            ( @(getter_name, prop_name) sprintf('''%s'', @()[eval(''%s;'')], ', getter_name, prop_name) ...
            , getter_names(:) ...
            , prop_names(getteri(:)) ...
            , 'UniformOutput', 0 ...
            );
        
        %for faster speed during dump() we would like property__ to have
        %two output arguments -- the second retreives all the values in one
        %step, as a struct, in one eval();
        dumpstructgetters = cellfun ...
            ( @(prop_name) sprintf('''''%s'''', {%s}, ', prop_name, prop_name)  ...
            , prop_names(getteri(:)) ...
            , 'UniformOutput', 0 ...
            );
        dumpstructmethods = cellfun...
            ( @(prop_name, getter_name) sprintf('''''%s'''', {this__.%s()}, ', prop_name, getter_name)...
            , prop_names(getmethodi(:)) ...
            , getmethod_names(:) ...
            , 'UniformOutput', 0 ...
            );
        
        dumpstruct = sprintf('@(this__)eval(''struct(  %s);'')', [dumpstructgetters{:} dumpstructmethods{:}]);
        dumpstruct(end-5:end-4) = [];
    
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
        
        string = cat(2, '{@(assignments__, this__) eval(''', assignmentstrings{:}, settingstrings{:}, '''), @() struct(', getterstrings{:}, setterstrings{:}, methodstrings{:}, '''property__'', [], ''method__'', [], ''version__'', []), ', dumpstruct, ', @(name__, func__)eval(''this.(name__) = func__;''), @(this__)eval(''this = this__;'')}');
        method_names = cat(1, getter_names(:), setter_names(:), method_names(:));
    end

end
