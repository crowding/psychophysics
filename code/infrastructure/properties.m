function this = properties(varargin)
%Creates a properties object, which can be inherited into any larger
%object. Aruments are as in <a href="matlab:help struct">struct</a> (without its support for creating cell
%arrays.) The properties object has getter and setter methods with names
%like getX and setX, and a field 'properties__' which lists the names of
%the properties.
%
%See also public, gettername, settername.

%make the core structure
if mod(nargin, 2)
    error('properties:illegalArgument', 'expected an even number of arguments');
end

[this, names, methodnames] = makeproperties(varargin{:});
    function [this, names, methodnames] = makeproperties(varargin)
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
        methodnames = {getterNames{:}, setterNames{:}}';
    end
names = names(:);

this.property__ = @property__;

    function value = property__(name, value)
        switch nargin
            case 0
                value = names;
            case 1
                %could this be made more efficient?
                value = this.(getterName(name))();
            otherwise
                value = this.(setterName(name))(value);
        end
    end

%this only exists to be used by publicize....
this.method__ = @method__;
    function value = method__(name, value)
        switch nargin
            case 0
                value = methodnames;
            case 1
                value = this.(name);
            otherwise
                error('publicize:cannotModify', 'cannot override methods here.');
        end
    end

this.version__ = getversion(2);
this = publicize(this);

end