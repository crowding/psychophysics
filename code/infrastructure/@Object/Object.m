function [this, varargout] = ObjectWrapper(varargin)
%take a nice object (which whould be a function-handled struct, etc.) and
%wrap it up with an object so that you get fun things like operator
%overloading, load/save wrappers, and so on without having to write it as
%one of those horrible MATLAB objects...
if (nargin > 1)
    [orig, varargout{1:nargout-1}] = inherit(varargin{:});
else
    orig = varargin{1};
end

if isa(orig, 'Object')
    this = orig;
else
    wrapped = orig;
    
    %record a handle to the 'constructor' of this object
    
    %this could be put in a subfunction, but evalin() doesn't seem to be
    %able to walk up the stack
    stack = dbstack;
    name = stack(2).name;

    if name(1) == '@'
        name(1) = [];
    else
        %only the final segment of a nested function name matters
        name = regexprep(name,'.*[^a-zA-Z0-9]', '');
    end
    handlegenerator = evalin('caller', sprintf('@()@%s', name));
    handle = handlegenerator();
    
    
    %wrap the methods in property wrappers... note that method__() should
    %continue to correctly extract the underlying methods!
    if isfield(orig, 'properties__');
        for prop = wrapped.properties__;
            gname = getterName(prop{:});
            sname = setterName(prop{:});
            getter = orig.(gname);
            setter = orig.(sname);
            
            % wrapped = rmfield(wrapped, {gname, sname})
            
            wrapped.(prop{:}) = PropertyWrapper(getter, setter);
        end
        
        %also wrap properties__ since it is expected to be just a cell
        %array
        [pget, pset] = accessor(wrapped.properties__);
        wrapped.properties__ = PropertyWrapper(getter, setter);
    end
    
    this.wrapped = wrapped;
    this.orig = orig;
    this.constructor__ = handle;

    this = class(this, 'Object');
end

%{
function [this, varargout] = ObjectWrapper(varargin)
%take a nice object (which whould be a function-handled struct, etc.) and
%wrap it up with an object so that you get fun things like operator
%overloading, load/save wrappers, and so on without having to write it as
%one of those horrible MATLAB objects...
if (nargin > 1)
    [wrapped, varargout{1:nargout-1}] = inherit(varargin{:});
else
    wrapped = varargin{1};
end

if isa(wrapped, 'ObjectWrapper')
    this = wrapped;
else
    this.wrapped = wrapped;
    %record a handle to the 'constructor' of this object
    
    %this could be put in a subfunction, but evalin() doesn't seem to be
    %able to walk up the stack
    stack = dbstack;
    name = stack(2).name;

    if name(1) == '@'
        name(1) = [];
    else
        %only the final segment of a nested function name matters
        name = regexprep(name,'.*[^a-zA-Z0-9]', '');
    end
    handlegenerator = evalin('caller', sprintf('@()@%s', name));
    handle = handlegenerator();
    
    this.constructor__ = handle;
    
    %wrap the methods in property wrappers... note that method() should
    %correctly extract the underlying methods!
    
    this = class(this, 'ObjectWrapper');
end
%}