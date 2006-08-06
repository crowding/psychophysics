function this = inherit(varargin)
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

%the names and methods of each direct ancestor (one cell per ancestor)
names = cellfun(@fieldnames, varargin, 'UniformOutput', 0);
methods = cellfun(@struct2cell, varargin, 'UniformOutput', 0);

%Others gets one cell per ancestor of each ancestor's other ancestors, i.e. 
%excluding the ancestor itself
others = arrayfun(@(index)exclude(varargin', index), 1:numel(varargin),...
    'UniformOutput', 0);
    function r = exclude(array, varargin)
        r = array;
        r(varargin{:}) = [];
    end

%Now, methods from ancestors listed later override methods from ancestors
%listed earlier. The nunion function tells us which methods come from where.

%indices gets index vectors of the selected method set, one cell per ancestor
indices = cell(size(names));
[m, indices{:}] = nunion(names{:});

names = restrict(names, indices);
methods = restrict(methods, indices);
    function cell = restrict(cell, indices)
        cell = cellfun(@(n,i) n(i), cell, indices, 'UniformOutput', 0);
    end

%build the new object by going through the methods coming from each
%ancestor
this = struct();
cellfun(@assignmethods, names, methods, others);
    function assignmethods(names, methods, others);
        %assign each method in turn
        cellfun(@assignmethod, names, methods);
        function assignmethod(name, method)
            
            %putmethod__ is our handle into the original object and will
            %not be overridden
            if strcmp('putmethod__', name)
                return
            end
            %store the method
            this.(name) = method;
            
            %Now tell the other ancestors about the new method
            cellfun(@putmethod, others);
            function putmethod(other)
                other.putmethod__(name, method);
            end
        end
    end

%Now, the "putmethod__' operation needs to be defined for the inherited
%object.
this.putmethod__ = @putparentmethods;
    function putparentmethods(name, fn)
        cellfun(@(parent) parent.putmethod__(name, fn), varargin);
    end
end