function this = public(varargin)
%function s = public(varargin)
%
%Given a bunch of function handles and variables to publically expose,
%PUBLIC creates a closure-based reference object.
%
%The arguments are all closures implementing the public methods.
%
%Unlike the object produced using FINAL, this one can be dynamically
%modified. New objects can inherit behavior from this one.

%TODO: something with public properties and default get/setters.
%(implementation musings: public properties should be implemented with a
%shadow object that is incorporated into the 'this' construct.
%
%TODO: something about interfaces (duck-typing for the win?)
%
%TODO: declaring public properties (they need to be
%persistent and modifiable?)

% ----- implementation -----
% This is sort of tricky, but shows how very powerful closures are.

%To allow ancestor code to call into inheritor code, we need
%to be able to effectively modify the 'this' structure that the ancestor
%code holds onto -- OR have the 'this' refer to something we can modify.

%Start with a 'final' object. But we keep it in this closure, and will
%instead return an indirection pointing to the core.
core = final(varargin{:});

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
    %implementation note: if we instead of a struct of wrappers used a
    %MATLAB object with overridden subsref(), the parent could call down
    %into methods it didn't even declare -- sort of an abstract base class.
    %For now I'm interested in using as few MATLAB objects as possible (how
    %fast is subsref dispatch vs. indirect struct lookup and funciton
    %handle dispatch?)

%Now, a call to this.methodName will look up whatever function is held in
%core.methodName and pass the call there. We put a mutator into this, so
%that we can modify what's in the core.
this.putmethod__ = @putmethod;
    function putmethod(name, fn)
        core.(name) = fn;
    end

%Now we can re-assign things to the core later on using putmethod__, and
%anyone having a copy or piece of the wrapped struct will now be able to 
%use the right method.

end