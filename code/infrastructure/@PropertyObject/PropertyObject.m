function p = PropertyObject(varargin)
% function p = PropertyObject([x, y, t])
% A structure suporting reasonable get/set methods.
% 
% [because I looked at the way MATLAB docs suggested writing accessors, and 
% felt sick. I barely have patience for languages that require me to write 
% accessors at all, let alone handling them by switch statements, and handling 
% inheritance manually.]
%
% Methods:
% p = set(p, 'PropertyName', value, ...) sets the named property. By default
%     the value is places into a field of hte same name if it exists. You can 
%     write your own set_PropertyName method to override this behavior. If
%     you write a method named check_PropertyName(p, value) returning a 
%     logical scalar, it will be used to verify new values.
%
% v = get(p, 'PropertyName') gets property values in the same way.
%     you can write a get_PropertyName method to override it.
%
% The 'getfield' and 'setfield' functions should be copied into each subclass of
% this class.

classname = mfilename('class');
args = varargin;

if length(args) > 0 && isa(args{1}, classname)
	%copy constructor
	p = args{1};
	args = args(2:end);
else
	%default values
	p.center = [0 0 0];
        p.svn = svninfo(fileparts(mfilename('fullpath')));
	p = class(p, classname);
end

%other initialization arguments
if length(args) >= 2
	p = set(p, args{:});
end
