function m = errormatch(fragment, identifier)
%ERRORMATCH(fragment, identifier)
%
%Determines if the fragment matches the error identifier given. The
%matching rules are:
%
%1. An error identifier matches a fragment if the identifier begins with the fragment.
%
%TODO: eventual desired matching rules are:
%
%1. A fragment matches if it is the entirely the same as the identifier.
%
%2. If a fragment begins with a colon, the match may start
%   later in the string. For example,
%   ':illegalArgument' matches 'component:subcomponent:illegalArgument'
%
%3. If a fragment ends with a colon, the match may end early. For example,
%   'MATLAB:' matches 'MATLAB:UndefilnedFunction'
%
%4. the empty string matches all.
m = numel(strmatch(fragment, identifier)) > 0;