function x = isobject(what)
x = builtin('isstruct', what) && builtin('isfield', what, 'property__');