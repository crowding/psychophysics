function varargout = require(varargin)

%function varargout = require(resource, ..., protected)
%
%REQUIRE acquires access to a limited resource before running a protected
%function; guaranteed to release the resource after running the protected
%function.
%
%REQUIRE takes multiple resource arguments.
%Each resource argument shoud be a function handle. When called, the
%resource function should acquire a resource (e.g. open a file , connect to
%a device, open a window on screen, etc.) The first argument returned by
%the resource function should be a releaser, another function handle, taking no
%arguments, that releases the resource in question.
%
%Initializers take one argument, that is a struct containing parameters
%used for their task; they modify this struct with additional fields and
%return it as their second output. So the form of an initializer is:
%
%function [releaser, params] = init(params)...
%
%
%Here is an example of usage. The function 'opener'
%bundles corresponding 'open' and 'close' operations together. Note how
%the 'fid' value is passed from 'opener' to 'write.'
%
%   require(@opener, @write);
%   function write(params)
%       fprintf(params.fid, 'Hello world!\n');
%   end
%
%   function [releaser, params] = opener(params)
%      params.fid = fopen(filename)
%      if params.fid < -1
%           error('could not open file');
%      end
%      releaser = @()close(fid);
%   end
%
% WHY THIS EXISTS: MATLAB's silly lack of a 'finally' clause or anything
% equivalent (e.g. the RAII idiom in C++) combined with a lot of
% boilerplate device-and-file-and-window-opening code in psychtoolbox
% scripts -- which is generally not written robustly, and should be
% collapsible down to a single command. Resource
% management is tricky even if you have good exception handling at your
% disposal; I want to encapsulate most of the tricky exception handling.

if (nargin < 2)
    error('require:illegalArgument', 'require needs at least 2 arguments');
end

if (nargin > 2)
    %if we have multiple initializers; use joinResource to combine them.

    init = joinResource(varargin{1:end-1});
    body = varargin{end};
    [varargout{1:nargout}] = require(init, body);
    return;
end

%run the initializer, collecting from it a release function handle and an
%optional output.
initializer = varargin{1};
body = varargin{2};

if ~isa(initializer, 'function_handle')
    error('require:badInitializer', 'initializer must be a function handle');
end

[releaser, output] = initializer(struct());

if ~isa(releaser, 'function_handle')
    error('require:missingReleaser', 'initializer did not produce a releaser');
end

%now either run the body, or recurse onto the next initializer
try
    if nargin(body) ~= 0
        [varargout{1:nargout}] = body(output); %run the curried, protected body
    else
        [varargout{1:nargout}] = body();
    end
catch
    %if there is a problem, rethrow the last error.
    err = lasterror;
    %log the error if a logger is among the parameters
    try
        if isfield(output, 'log')
            output.log('ERROR %s', err.identifier);
        end
    catch
        err = adderror(lasterror, err);
    end
    try
        releaser();
    catch
        err = adderror(lasterror, err);
    end
    rethrow(err);
end

%finally, release the resource.
releaser();