function this = publicize(this)
%Wraps up a structure of function handles so that they can be
%modified by reference, and the modifications will have effect for any
%context that has a copy of the structure. The handles are modified by
%using the function method__ which is placed in a new field of the
%structure. This is used to make objects that can be inherited from (as in
%
%See also final, public, properties.

%replace 'this' with a dereferenced implementation and a shadow full of
%mutators.

names = this.method__();
for i = names'
    [this.(i{:}), shadow.(i{:})] = reassignableFunction(this.(i{:}));
end
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

%We also define the special function,
%method__, so that we can access or modify what's the functions are
%redirected to.
this.method__ = @method;
    function fn = method(name, fn)
        switch nargin
            case 0
                fn = names;
            case 1
                %shadow is a struct of accessor/mutators
                fn = shadow.(name)();
            otherwise
                shadow.(name)(fn);
        end
    end



end