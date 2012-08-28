function props = xpropertiesfromdefaults(defaults, extraname, varargin)
%function props = propertiesfromprototype(defaults, extraname, varargin);
%
%a version of propertiesfromdefaults that puts extra params in the
%requested variable using assignin, instead of as a property.
%
%a pattern for initializing the arguments from properties.
%
%defaults - a structure containing your defaults.
%extraname - the field under which anything not matching the fields in
%            'default' will be placed
%varargin - your varargin.

defaults = namedargs(defaults);
[args, extras] = interface(defaults, namedargs(defaults,varargin{:}));
args = namedargs(args);

assignin('caller', extraname, extras);

arglist = struct2arglist(args);
props = objProperties(arglist{:});