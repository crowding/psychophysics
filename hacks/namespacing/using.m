function var = using(folder)
%this is an attempt to provide some kind of namespace functionality for
%matlab. If you wish to use code, objects, etc. that are located in the
%"foo" directory, call:
%
%using foo;
%
%and a structure 'foo' containing apropriate functions will be brought into
%your namespace. Functions in the 'foo' directory can now be called through
%this structure:
%
%foo.function(arguments) (would call the code in the file foo/function.m)
%
%You can asign the import to different name as well:
%
%bar = using('foo');
%
%in which case 
%then use function calls by 

%the cache is a struct, one entry for each folder name. 
%Values are structs, mapping names fo function pointer values.
persistent cache;

%this keeps the matlab path at one step removed, but we still use it...
if numel(cache) == 0;
    cache = struct;
end

%we look up the folder name in the cache, and find a bunch of stuff(function 
%references, class names) which we dump into the parent's namespace. 
%assign to the parent.

if isfield(cache,folder)
    names = cache_names.(folder);
    values = cache_values.(folder);
else
    
end

%bring the declarations to the top
cellfun(@(nam, val)assignin('caller', nam, val), names, values);