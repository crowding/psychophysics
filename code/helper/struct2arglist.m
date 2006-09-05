function arglist = struct2arglist(s)
%convers a struct into a cell array suitable for apssing as an argument
%list. Ideally this would be a simple inverse of struct(), but matlab's 
%struct() is not simple (it has *astonishing* behavior on cell array
%arguments:)
%
%>> struct('a', 1)
%ans = 
%    a: 1
%>> struct('a', {1})
%ans = 
%    a: 1
%>> struct('a', {1, 2})
%ans = 
%1x2 struct array with fields:
%    a
%>> struct('a', {})
%ans = 
%0x0 struct array with fields:
%    a
%
% There are two overlapping behaviors: the behavior when the value to put
% in a field is a cell array, and the value when it is any other type. This
% makes it tricky to use struct() to make scalar whose field values are
% themselves cell arrays:
%
% >> struct('a', {1, 2}, 'b', {3, 4, 5})
%??? Error using ==> struct
%Array dimensions of input 4 must match those of input 2 or be scalar.
%
% To acheive the intended effect, you must double-wrap such arguments:
%
%>> struct('a', {{1, 2}}, 'b', {{3, 4, 5}})
%ans = 
%    a: {[1]  [2]}
%    b: {[3]  [4]  [5]}
%
% Further complicating this is that struct() does 'scalar expansion' of
% non-cell or single-cell arguments.
%
%>> struct('a', {1, 2}, 'b', {3})
%ans = 
%1x2 struct array with fields:
%    a
%    b
%>> ans.b
%ans =
%     3
%ans =
%     3
%
%From this we can conclude that the only consistent, general way to use
%struct() is to enclose all values in cell arrays. But most functions that
%take an argument list aren't going to like this. So struct2arglist is not
%an inverse of struct() in the general case
%
%The output is a single cell array, since in matlab you can't use
%comma-separated lists most places you'd want to interpolate struct2arglist.
%You'll have to hold the result in a variable and interpolate it in the
%next line:
%
%optionslist = struct2arglist(plotoptions);
%plot(xx, yy, optionslist{:});
%
%[we'd like to be able to say plot(xx, yy, struct2arglist(plotoptions)),
%and you can indeed say such things in e.g. Mathematica, not in matlab.]

if (numel(s) ~= 1)
    error('struct2arglist:illegalArgument', ...
        'non-scalar struct arrays are not handled by struct2arglist.');
end

tmp = cat(2, fieldnames(s), struct2cell(s))';
arglist = tmp(:);