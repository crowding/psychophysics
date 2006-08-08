function s = final(varargin)
%Create a struct object out of a bunch of closures. The result is not
%designed to be inherited from, and is consequently faster than PUBLIC 
%(losing a level of indirection.)

%Matlab annoyance:
%
%fn = @(varargin) size(varargin)
%
%then fn(1, 2, 3, 4) -> [1 4]
%and  fn(1, 2, 3)    -> [1 3]
%and  fn(1, 2)       -> [1 2]
%and  fn(1)          -> [1 1]
%but  fn()           -> [0 0], and not [1 0].
%
%this is annoying.
%
%particularly when there are functions, for instance cell2struct, which
%treat a [0 0] cell array different from a [1 0] cell array.
%since I want my function to work for 0 arguments as well, I have to make
%this defense:
if (numel(varargin) == 0)
    varargin = cell([1 0]);
end

methods = varargin;
method_info = cellfun(@functions, methods);
method_names = arrayfun(@(x)x.function, method_info, 'UniformOutput', 0);
%nested functions are denoted with a slashed path
method_names = regexprep(method_names, '.*/', '');

s = cell2struct(methods, method_names, 2); %varargin comes as a row vector