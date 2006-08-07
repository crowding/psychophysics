function this = publicize(core)
    %wraps up a structure of function handles so that its methods can be
    %modified by reference, and the modofications will have effect for any
    %context that has a copy of the structure. THis is used to make objects
    %that can be inherited from (as in PUBLIC and PROPERTIES).
    
%We add a layer of indirection, by wrapping each function to refer to the 
%core.
this = cellfun(@wrap, fieldnames(core), 'UniformOutput', 0);
    function w = wrap(name)
        w = @wrapper;
        
        function varargout = wrapper(varargin);
            fn = core.(name);
            [varargout{1:nargout}] = fn(varargin{:});
        end
    end
this = cell2struct(this, fieldnames(core), 1);

%Now, a call to this.methodName will look up whatever function is held in
%core.methodName and pass the call there. We also add a special function,
%putmethod__, so that we can modify what's in the core struct
this.putmethod__ = @putmethod;
    function putmethod(name, fn)
        core.(name) = fn;
    end

%Now we can re-assign things to the core later on using putmethod__, and
%anyone having a copy or piece of the wrapped struct will now be able to 
%use the right method.

end