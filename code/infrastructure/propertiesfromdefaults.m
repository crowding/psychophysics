function props = propertiesfromdefaults(defaults, extraname, varargin)
%function props = propertiesfromprototype(defaults, extraname, varargin);
%
%a pattern for initializing the arguments from properties.
%
%defaults - a structure containing your defaults.
%extraname - the field under which anything not matching the fields in
%            'default' will be stuffed (as a substruct)
%varargin - your varargin.

defaults = namedargs(struct(extraname, struct()), defaults);
[args, extras] = interface(defaults, namedargs(defaults,varargin{:}));
args = namedargs(args, struct(extraname, extras));

arglist = struct2arglist(args);
props = properties(arglist{:});