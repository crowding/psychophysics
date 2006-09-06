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
        this = public();
    case 1
        this = varargin{1};
    otherwise
        [this, varargout{1:nargout-1}] = inherit(varargin{:});
        this.version__ = getversion(2);
end

if isa(this, 'Object')
    return;
else
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
    
    this = struct(...
        'wrapped', this...
        ,'version', getversion(2)...
        ,'constructor', constructor...
        ,'getters', getgetters(this)...
        ,'setters', getsetters(this)...
        );

    this = class(this, 'Object');
end

end

function getters = getgetters(wrapped)
    propnames = wrapped.property__();
    fns = cellfun(@(n)wrapped.method__(getterName(n)), propnames, 'UniformOutput', 0);
    args = {propnames{:}; fns{:}};
    getters = struct(args{:});
end

function setters = getsetters(wrapped)
    propnames = wrapped.property__();
    fns = cellfun(@(n)wrapped.method__(setterName(n)), propnames, 'UniformOutput', 0);
    args = {propnames{:}; fns{:}};
    setters = struct(args{:});
end