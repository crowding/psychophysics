function varargout = require(varargin)

%function varargout = require(params, resource, ..., protected)
%
%REQUIRE acquires access to a limited resource before running a protected
%function; guaranteed to release the resource after running the protected
%function.
%
%The optional first argument is a parameter structure. This is passed to
%the first initializer. The output from the first initializer is passed to
%the second initializer, and so on.
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

if isstruct(varargin{1})
    params = varargin{1};
    varargin(1) = [];
else
    params = struct();
end

if (numel(varargin) < 1)
    error('require:illegalArgument', 'require needs at least 1 function handle');
end

%run the initializer, collecting from it a release function handle and an
%optional output.
if ~isa(varargin{1}, 'function_handle')
    error('require:badInitializer', 'initializer must be a function handle');
end
if numel(varargin) > 1
    %call the initializer here
    s = resourcecheck();
    if nargin(varargin{1}) == 0
        varargin{1}(); %probably it's a rogue releaser, call it anyway.
        error('require:notEnoughInputs', 'Initializers must take a struct input. Did you call the initializer by leaving off an @-sign?');
    else
        if nargout(varargin{1}) > 2
            %a initializer can also give a 'next initializer' as output.
            %This switches on nargout, whcih is fail, but better than
            %nothing.
            [releaser, params, next] = varargin{1}(params);
            varargin{1} = next;
        else
            [releaser, params] = varargin{1}(params);
            varargin(1) = [];
        end
    end

    if ~isa(releaser, 'function_handle')
        error('require:missingReleaser', 'initializer did not produce a releaser');
    end

    %CHECK IN
    resourcecheck(s, releaser); %check in with this releaser

    %now run the body
    try
        if (numel(varargin) > 0)
            %recurse
            [varargout{1:nargout}] = require(params, varargin{:});
        else
            body = varargin{2};
            if nargin(body) ~= 0
                [varargout{1:nargout}] = body(params);
            else
                [varargout{1:nargout}] = body();
            end
        end
    catch
        %if there is a problem, run the releaser and then rethrow the last error.
        err = lasterror;
        %log the error if a logger is among the parameters
        try
            if isfield(params, 'log')
                params.log('ERROR %s', err.identifier);
            end
        catch
            err = adderror(lasterror, err);
        end
        try
            resourcecheck(s);
            releaser();
        catch
            err = adderror(lasterror, err);
        end
        %SUPER DUMB MATLAB FEATURE! Rethrow() cuts off the display of
        %the stack trace. Use error() instead and it will not, but instead
        %replicates the error message.
        rethrow(err);
    end
    
    resourcecheck(s);
    releaser();
else
    body = varargin{1};
    if nargin(body) ~= 0
        [varargout{1:nargout}] = body(params);
    else
        [varargout{1:nargout}] = body();
    end
end


end