function this = ApparentMotion(varargin)
% function c = ApparentMotion([CauchyPatch], 'propname', value, ...)
% Constructor for apparent motion simuli. The stimulus is composed of a
% Patch that is repeated while moving over intervals of dx and dt.
%
% Inherits from Patch.
%
% Additional Properties:
% 'primitive' the Patch that is displayed at each station
% 'dx' the distance in x between showings of the primitive
% 'dt' the distance in y between showings of the primitive
% 'n' the number of frames

classname = mfilename('class');

%default values
defaults = struct ...
    ( 'primitive',  Bar ...
    , 'dx', 1 ...
    , 'dt', 0.1 ...
    , 'n', 10 ...
    , 'svn', svninfo(fileparts(mfilename('fullpath'))) ...
    );
this = class(defaults, classname, Patch);

this = namedargs(this, varargin{:});
