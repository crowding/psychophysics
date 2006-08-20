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

%If requested, save a reference copy of the methods from each ancestor.
%This is so you can still call a method you override through inheritance.

this = struct();
this.parents__ = cellfun(@parent_backup, varargin, 'UniformOutput', 0);
    function backup = parent_backup(parent)
        backup = parent;
        %ordinary methods need to get unwrapped
        parentmethodnames = fieldnames(parent);
        which = regexp(parentmethodnames, '__$', 'once');
        which = ~cellfun(@isempty, which);
        parentmethodnames(which) = [];
        for name = parentmethodnames'
            backup.(name{:}) = parent.method__(name{:});
        end
    end

varargout = this.parents__(1:nargout-1);

%the names and methods of each direct ancestor (one cell per ancestor)
names = cellfun(@fieldnames, varargin, 'UniformOutput', 0);

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
names = cellfun(@(n,i) n(i), names, indices, 'UniformOutput', 0);
%Now names only contains the methods that will end up being publically
%exposed.

%build the new object by going through the methods coming from each
%ancestor
cellfun(@assignmethods, names, varargin, others);
    function assignmethods(names, obj, others);
        %names  is the names of the methods to assign
        %obj    is the object where the methods come from
        %others is the other objects that get the method

        %assign each method in turn
        cellfun(@assignmethod, names);
        function assignmethod(name)
            
            %double-underscpre fields are special and will not be
            %overridden
            if ~isempty(regexp(name, '__$', 'once'));
                return
            end
            
            %get the actual method (not the transparent invoker)
            method = obj.method__(name);
            
            %store the method
            this.(name) = method;

            %Now tell the other ancestors about the new method
            cellfun(@putmethod, others);
            function putmethod(other)
                %the other object only gets the method if it has a slot for
                %it
                if isfield(other, name);
                    other.method__(name, method);
                end
            end
        end
    end

%Now, the "putmethod__' operation needs to be defined for the inherited
%object.
this.method__ = @putparentmethods;
    function fn = putparentmethods(name, fn)
        %when just getting a method, just the first method should be OK.
        if (nargin < 2)
            fn = this.(name); %since inherited 'this' contains the raw
            %methods.
        else
            %store the method, and store it in the ancestors
            this.(name) = fn;
            cellfun(@putparentmethod, varargin);
        end
        
        function putparentmethod(parent)
            if isfield(parent, name)
                parent.method__(name, fn);
            end
        end
    end
end