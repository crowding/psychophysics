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
%The initializer can optionally return a second parameter, which can 
%describe the resource acquired (e.g. filehandle, screen/window number, 
%calibration information, etc.) 
%
%Another function RESOURCE exists that may help in procuring the
%appropriate function handles. 
%
%REQUIRE
%
%Here is an example of usage without 'resource'. The function 'opener'
%bundles corresponding 'open' and 'close' operations together. Note how
%the 'fid' value is passed from 'opener' to 'write.'
%
%   require(@opener, @write);
%   function write(fid)
%       fprintf(fid, 'Hello world!\n');
%   end
%
%   function [r, fid] = opener
%      fid = fopen(filename)
%      if fid < -1
%           error('could not open file');
%      end
%      r = @()close(fn);
%   end
%
%
%Here is a more compact example using RESOURCE to make the function
%handles. 
%
%   require(resource(@fopen, @fclose, 'out.txt', 'W'), @write);
%   function write(fid)
%       fprintf(fid, 'Hello world!\n');
%   end
%
% REQUIRE can take multiple releaser arguments, in which case the optional 
% outputs of the releaser are gathered into a cell array to be passed to
% the body.
%
% WHY THIS EXISTS: MATLAB's silly lack of a 'finally' clause or anything
% equivalent (e.g. the RAII idiom in C++) combined with a lot of
% boilerplate device-and-file-and-window-opening code in psychtoolbox
% scripts -- which is generally not written robustly, and should be
% collapsible down to a single file.

if (nargin < 2)
    error('require:illegalArgument', 'require needs at least 1 argument');
end

%run the initializer, collecting from it a release function handle and an
%optional output.
initializer = varargin{1};

if ~isa(initializer, 'function_handle')
    error('require:missingReleaser', 'initializer did not produce a releaser');
end

initializer_outputs = nargout(initializer);
if initializer_outputs < 1
    error('require:illegalArgument', 'initializers need to produce a releaser');
else
    [releaser, output{1:initializer_outputs - 1}] = initializer();
end

if ~isa(releaser, 'function_handle')
    error('require:missingChainOutputCollection', 'initializer did not produce a releaser');
end

%now either run the body, or recurse onto the next initializer
try
    body = varargin{end};
    if (nargin > 2)
        %we have more initializers --
        %recurse onto the next initializer, currying the initializer's
        %output with the body function.
        newbody = @(varargin) body(output{:}, varargin{:});
        require(varargin{2:end-1}, newbody);
    else
        %we have initialized everything - run the body
        [varargout{1:nargout}] = body(output{:}); %run the curried, protected body
    end
catch
    %if there is a problem, rethrow the last error.
    err = lasterror;
    releaser();
    rethrow(err);
end

%finally, release the resource.
releaser();