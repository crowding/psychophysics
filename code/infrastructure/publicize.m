function this = publicize(this)
    %wraps up a structure of function handles so that its methods can be
    %modified by reference, and the modofications will have effect for any
    %context that has a copy of the structure. THis is used to make objects
    %that can be inherited from (as in PUBLIC and PROPERTIES).

%replace 'this' with a dereferenced implementation and a shadow full of
%mutators.
[this, shadow] = structfun(@reassignableFunction, this, 'UniformOutput', 0);
    function [fout, accessor] = reassignableFunction(fin)
        fout = @invoke;
        accessor = @access;
        
        function varargout = invoke(varargin)
            [varargout{1:nargout}] = fin(varargin{:});
        end
        
        function f = access(f)
            if (nargin == 0)
                f = fin;
            else
                fin = f;
            end
        end
    end

%We also add a special function,
%method__, so that we can access or modify what's in the core struct:

%Now we can re-assign functions using method__, and
%anyone having a copy or piece of the wrapped struct will now be able to 
%use the right method.

this.method__ = @method;
    function fn = method(name, fn)
        %shadow is a struct of accessor/mutators
        if (nargin < 2)
            fn = shadow.(name)();
        else
            shadow.(name)(fn);
        end
    end
end