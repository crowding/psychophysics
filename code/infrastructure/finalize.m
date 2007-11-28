function obj = finalize(obj)

persistent warned;
if isempty(warned)
    warned = struct();
end
parent = evalin('caller', 'mfilename');
if ~isfield(warned, parent)
    warning('finalize:deprecated', 'finalize is obsolete, switch to autoobject');
    warned.(parent) = 1;
end

    if ~isfield(obj, 'method__')
        error('finalize:notAnObject', 'Argument is not an object and cannot be finalized.');
    end
    
    methods = obj.method__();
    
    obj = unwrapMethods(obj);
    function obj = unwrapMethods(obj)
        for m = methods'
            obj.(m{:}) = obj.method__(m{:});
        end
    end

    obj.method__ = @method__;
    function val = method__(name, val)
        switch nargin
            case 0
                val = methods;
            case 1
                val = obj.(name);
            otherwise
                error('finalize:cannotModify','cannot override methods in finalized objects.');
        end
    end

    %properties stay unmodified?
end