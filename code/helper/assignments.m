function arglist = assignments(arglist, varargin)

%when converting an object constructor from regular calling to
%named-arguments calling convention, this helps with backwards 
%compatibility by making assignments to the calling function's variables.
%
%example usage:
%
%function this = object(varargin)
%   x = 0;
%   y = 0;
%
%   varargin = assignments(varargin, 'x', 'y')
%   this = autoobject(varargin{:});
%end
%
%Thereafter object can be constructed either as
%object(1, 2) or as 
%object('x', 1, 'y', 2).

while (~isempty(varargin)) && (~isempty(arglist)) && (~isvarname(arglist{1}))
    assignin('caller', varargin{1}, arglist{1});
    varargin(1) = [];
    arglist(1) = [];
end
