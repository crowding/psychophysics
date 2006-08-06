function s = final(varargin)
%Create a struct object out of a bunch of closures. The result is not
%designed to be inherited from, and is consequently faster than PUBLIC 
%(losing a level of indirection.)

methods = varargin;
method_info = cellfun(@functions, methods);
method_names = arrayfun(@(x)x.function, method_info, 'UniformOutput', 0);
%nested functions are denoted with a slashed path
method_names = regexprep(method_names, '.*/', '');

s = cell2struct(methods, method_names, 2); %varargin comes as a row vector