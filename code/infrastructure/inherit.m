function [this, varargout] = inherit(varargin)
%Muddles the methods of all the given objects together, to form a new
%object that inherits all their methods. Performs special magic so that
%the muddled objects can call each other's methods through each's respective
%'this' structure (assuming each was created with PUBLIC).

%Basically we have to create a struct that has all the right methods. Less
%besically, we have to make sure that ancestors can call the child methods
%(or the spouse methods, in the case of multiple inheritance.)
%
%Now, when A inherits from B, we have to tell B to use A's methods, and
%vice versa, which is accomplished using the putmethod__ method on each.
%So we have to take the aggregate method listing and putmethod__ it into
%each of the ancestors.
%
%But if we tell B to use B's methods, we get an infinite loop. B calls a
%function which in turn calls B, and so on. So we have to put each method
%into all the ancestors EXCEPT the one they originated from...
%
%For the same reason, diamond-inheritance, where the selfsame instance is
%ancestor to two different ancestors, also leads to loops. But in that
%case, I don't have an easy way to get around it, because I don't yet have
%a way to uniquely identify objects. So, avoid inbreeding your objects.
%
%If requested, save a reference copy of the methods from each ancestor.
%This is so you can still call a method you override through inheritance.

[this, shadow] = inheritmethods(varargin);
    function [this, shadow] = inheritmethods(parents_);
        
        %method-methods of each direct ancestor (one cell per ancestor)
        methodMethods = cellfun(@(p)p.method__, parents_, 'UniformOutput', 0);

        backup = cell(size(parents_));
        for i = 1:numel(parents_)
            backup{i} = cell2struct(struct2cell(parents_{i}),fieldnames(parents_{i}));
            for name = methodMethods{i}()'
                backup{i}.(name{:}) = methodMethods{i}(name{:});
            end
        end
        
        %from each object the names of the methods we will inherit from it.
        allMethods = cellfun(@(f)f(), methodMethods, 'UniformOutput', 0);

        methodnames = nunion(allMethods{:});
        %build a logical array that holds a mark for each object that implements
        %each method. Methods along columns, parents in rows.
        hasMethod = logical(zeros(numel(parents_), numel(methodnames)));
        for i = 1:numel(parents_)
            j = intersectionIx(methodnames, allMethods{i})';
            hasMethod(i, j) = 1;
        end
        
        %the inherited method is the last one in every row...
        [tmp, inheritedMethodIx] = max(flipud(hasMethod));
        inheritedMethodIx = size(hasMethod, 1) + 1 - inheritedMethodIx;

        %the overridden methods are the other ones
        overriddenMethod = hasMethod;
        overriddenMethod(sub2ind(size(overriddenMethod), inheritedMethodIx, 1:numel(methodnames))) = 0;
        
        thisargs = cell(1, 2*numel(methodnames));
        shadowargs = cell(1, 2*numel(methodnames));
        
        %now stuff the methods in...
        for i = 1:numel(methodnames)
            methodname = methodnames{i};
            
            thisargs{2*i-1} = methodname;
            shadowargs{2*i-1} = methodname;
            
            method = methodMethods{inheritedMethodIx(i)}(methodname);

            
            [thisargs{2*i}, shadowargs{2*i}] = reassignableFunction(method);
            for p = methodMethods(overriddenMethod(:,i)) %logical indexing
                p{:}(methodname, method);
            end
        end
        
        %and stuff in an implementation of method__ using these precomputed
        %matrices? for the fastness!
        
        function val = method__(name, val) %this should be inside a version of reassignableMethod...
            switch(nargin)
                case 0
                    val = methodnames;
                case 1
                    val = shadow.(name)();
                otherwise
                    i = find(strcmp(name, methodnames));
                    if ~isempty(i)
                        
                        for p = methodMethods(hasMethod(:,i)) %logical indexing
                            p{:}(name, val);
                        end
                        shadow.(name)(val);
                    end
                    %otherwise assigning the method has no effect
            end
        end
        
        this = struct(thisargs{:}, 'method__', @method__, 'parents__', {backup});
        shadow = struct(shadowargs{:});
    end

%i doubt this...
%this = publicize(this);

varargout = this.parents__(1:nargout-1);

%another matlab annoyance: if you hav a bunch of code and have left off a
%semicolon somewhere, there is no good way to track down where short of
%breaking out the debugger.

%and similarly the property() method needs to be defined.
this.property__ = makeproperty();
    function fn = makeproperty
        propnames = {};
        for i = this.parents__
            if isfield(i{:}, 'property__')
                propnames = union(propnames, i{:}.property__());
            end
        end
        
        %it's totally unpredictable what way matlab's UNION will want to
        %orient its output
        propnames = propnames(:);
        
        %pull otu getter and setter methods.
        %i'd do this with a cellfun but it adds an inexplicable 0.4
        %seconds, thanks to matlab's incredibly slow use of structs and
        %cells in lexical scope
        getters = cell(size(propnames));
        for i = 1:numel(getters)
            getters{i} = this.(getterName(propnames{i}));
        end
        getters = {propnames{:}; getters{:}};
        getters = struct(getters{:});

        setters = cell(size(propnames));
        for i = 1:numel(setters)
            setters{i} = this.(setterName(propnames{i}));
        end
        setters = {propnames{:}; setters{:}};
        setters = struct(setters{:});

        fn = @property__;
        function val = property__(name, val);
            switch nargin
                case 0
                    val = propnames;
                case 1
                    val = getters.(name)();
                otherwise
                    setters.(name)();
            end
        end
    end

%put in versioning information.
this.version__ = getversion(2);

end