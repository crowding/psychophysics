function [this, varargout] = inherit(varargin)
%Muddles the methods of all the given objects together, to form a new
%object that inherits all their methods. Performs special magic so that
%the muddled objects can call each other's methods through each's respective
%'this' structure (assuming each was created with PUBLIC).
%
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

%Each parent has a list of methods and properties. The rightmost parent in
%the list to have each method or property gets it for all properties.
%Therefore each parent should have the same this() following the
%inheritance.

%Get the list of all methods and the canonical form of each parent.
methodlists = cell(size(varargin));
parents = cell(size(varargin));
for i = 1:numel(varargin)
    [methodlists{i}, parents{i}] = varargin{i}.method__();
end

[methodnames, methodindices{1:numel(methodlists)}] = nunion(methodlists{:});

%The combined version__ should include the version of all appropriate
%parents in the appropriate order..
version__ = getversion(2);
version__.parents = cellfun(@(x)x.version__, parents);

%Pull out each method name and the corresponding method
args = cell(2, numel(methodnames));
ix = 1;
for i = 1:numel(methodindices)
    for j = 1:numel(methodindices{i})
        args{1,ix} = methodlists{i}{methodindices{i}(j)};
        args{2,ix} = parents{i}.(args{1,ix});
        ix = ix + 1;
    end
end

%now create the 'this' struct
this = struct(args{:}, 'property__', @property__, 'method__', @method__, 'version__', version__);

%stuff it into every parent
for i = 1:numel(parents)
    parents{i}.method__(this);
end

%keep a lookup table of which property methods to use
propertylists = cellfun(@(x)x.property__(), parents, 'UniformOutput', 0);
[propertynames, propertyindices{1:numel(propertylists)}] = nunion(propertylists{:});
args = cell(2, numel(propertynames));
ix = 1;
for i = 1:numel(propertyindices);
    for j = 1:numel(propertyindices{i})
        args{1,ix} = propertylists{i}{propertyindices{i}(j)};
        args{2,ix} = parents{i}.property__;
        ix = ix + 1;
    end
end
propertymethods = struct(args{:});

    %The combined method__ should get the method from what's stored here
    %and set the method in all parents as well as here.
    function [methods, canonical, par] = method__(name, value)
        switch nargin
            case 0
                methods = methodnames;
                canonical = this;
                par = parents;
            case 1
                if isstruct(name) %wholesale inheritance
                    for i = 1:numel(parents)
                        parents{i}.method__(name)
                    end
                    this = name;
                else
                    methods = this.(name);
                end
            case 2
                for i = 1:numel(parents)
                    parents{i}.method__(name, value)
                end
                this.(name) = value;
        end
    end

    %The combined property__ should set the property in the appropriate parent.
    function [value, st] = property__(name, value)
        %which parent is correct?
        
        switch nargin
            case 0
                %all property names
                value = propertynames;
                if nargout > 1
                    s = cell(size(parents));
                    for i = 1:numel(parents)
                        [tmp, s{i}] = parents{i}.property__();
                        s{i} = struct2cell(s{i});
                    end
                    
                    pl = propertylists;
                    for i = 1:numel(pl)
                        pl{i} = pl{i}(propertyindices{i});
                        %must wrap each element in a cell for struct...
                        s{i} = num2cell(s{i}(propertyindices{i}));
                    end
                    
                    %must wrap args to struct in cells
                    args = cat(1, cat(1, pl{:})', cat(1, s{:})');
                    st = struct(args{:});
                end
            case 1
                value = propertymethods.(name)(name);
            case 2
                propertymethods.(name)(name, value);
        end
    end


varargout = parents;
end