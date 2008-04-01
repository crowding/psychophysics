function does = respondsto(obj, m)

does = isstruct(obj) && isfield(obj, 'method__') && isa(obj.(m), 'function_handle');