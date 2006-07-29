function s = public(varargin)
%function s = public(varargin)
%Given a bunch of function handles and variables to publically expose,
%PUBLIC creates a closure-based reference object.
%This is the basic magic that tuns a disused matlab feature (nested
%functions) into a useful object system.
%
%The arguments are all function handles declaring public methods.

%TODO: accept preformed structs (inheritance)
%TODO: something with properties and default get/setters.
%(implementation musings: public properties should be implemented with a
%shadow object that is incorporated into the 'this' construct.
%
%TODO: something about inheritance of methods and properties
%(implementation musings: super methods should be able to call derived
%methods via the this() somehow (unclear on mechanism.) Derived classes can
%call super methods via this.method() as well.
%
%TODO: something about interfaces (duck-typing for the win?)
%
%TODO: somethign about class properties (they just need to be
%persistent)
methods = varargin;
method_info = cellfun(@functions, methods);
method_names = {method_info.function};
%nested functions are denoted with a slashed path
method_names = regexprep(method_names, '.*/', '');

s = cell2struct(methods, method_names, 2); %varargin comes as a row vector