function [this, varargout] = Object(varargin)
%take a nice object (which whould be a function-handled struct, etc.) and
%wrap it up with an object so that you get fun things like operator
%overloading, load/save wrappers, and so on without having to write it as
%one of those horrible MATLAB objects...
%
%Object() is pretty slow and heavyweight, and should be
%used for non-time-critical things that you need to save to disk.
%Experiment parameters, trial generators and outcomes, and so on.
%
switch(nargin)
    case 0
        orig = public();
    case 1
        orig = varargin{1};
    otherwise
        [orig, varargout{1:nargout-1}] = inherit(varargin{:});
end

if isa(orig, 'Object')
    this = orig;
else
    wrapped = orig;
    
    %record a handle to the 'constructor' of this object
    
    %this could be put in a subfunction, but evalin() doesn't seem to be
    %able to walk up the stack
    stack = dbstack;
    if numel(stack) >= 2
        name = stack(2).name;

        if name(1) == '@'
            name(1) = [];
        else
            %only the final segment of a nested function name matters
            name = regexprep(name,'.*[^a-zA-Z0-9]', '');
        end
        handlegenerator = evalin('caller', sprintf('@()@%s', name));
        handle = handlegenerator();
        constructor = handle;
    else
        constructor = [];
    end
    
    %wrap the methods in property wrappers... note that method__() should
    %continue to correctly extract the underlying methods!
    if isfield(orig, 'properties__');
        for prop = (wrapped.properties__(:))';
            gname = getterName(prop{:});
            sname = setterName(prop{:});
            getter = orig.(gname);
            setter = orig.(sname);
            
            wrapped.(prop{:}) = PropertyWrapper(getter, setter);
        end
        
        %also wrap properties__ since it is expected to be just a cell
        %array
        [pget, pset] = accessor(wrapped.properties__);
        wrapped.properties__ = PropertyWrapper(pget, pset);
    end
    
    this.wrapped = wrapped;
    this.orig = orig;
    this.constructor__ = constructor;

    this = class(this, 'Object');
end