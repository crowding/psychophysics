function this = properties(varargin)
%creates a properties object, which can be inherited into any larger
%object.

%make the core structure
if mod(nargin, 2)
    error('properties:illegalArgument', 'expected an even number of arguments');
end

names = varargin(1:2:end);
values = varargin(2:2:end);

if any(~all(cellfun(@isvarname, names)))
    error('properties:illegalArgument', 'property names must be valid variable names');
end

%make getters and setters arounnd each value
[getters, setters] = cellfun(@accessor, values, 'UniformOutput', 0);

%assign names to them
getterNames = cellfun(@getterName, names, 'UniformOutput', 0);
setterNames = cellfun(@setterName, names, 'UniformOutput', 0);

%put them all in a struct (all arguments to this struct() call are scalars,
%so we don't trip struct()'s astonishing behavior with cell array
%arguments)
tostruct = {getterNames{:}; getters{:}; setterNames{:}; setters{:}};
this = struct(tostruct{:});

%this is a behind the scenes object so I will use the ugly boilerplate for
%speed
this.method__ = @method__;
    function val = method__(name, val);
        if nargin > 1
            %I suppose this doesn't actually have any purpose, since
            %nothing in this context will call the getters or setters?
            this.(name) = val;
        else
            val = this.(name);
        end
    end

this.properties__ = names;
%that boilerplate did the same job as 'this = publicize(this)' but directly,
%so it is faster.

end