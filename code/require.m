function require(varargin)
%
%function require(resource, ..., protected)
%
%REQUIRE acquires access to a limited resource before running a protected
%function; guaranteed to release the resource after running the protected
%function.
%
%REQUIRE takes multiple resource arguments.
%Each resource argument shoud be a function handle. When called, the 
%resource function should acquire a resource (e.g. open a file , connect to
%a device, open a window on screen, etc.) and optionally return parameters
%describing the resource (e.g. filehandle, screen/window number, 
%calibration information, etc. The last argument returned by the resource
%function should be a releaser, another function handle, taking no
%arguments, that releases the resource in question.
%
%Another function RESOURCE exists that may help in procuring the
%appropriate function handles. 
%
%REQUIRE
%
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

if (nargin < 2)
    error('require:illegalArgument', 'require needs at least 2 arguments');
end

initializer = varargin{1};

if ~isa(initializer, 'function_handle')
    error('require:illegalArgument', 'require takes function handles as arguments');
end

%run the initializer, collecting from it a release function handle and an
%optional set of outputs.
initializer_outputs = nargout(initializer);
if initializer_outputs < 1
    error('require:badInitializerNargout', 'initializers need to produce a releaser');
else
    [release, output{1:initializer_outputs-1}] = initializer();
end

if ~isa(release, 'function_handle')
    error('require:missingReleaser', 'initializer did not produce a releaser');
end

%now run the body, or the next initializer
try
    body = varargin{end};
    if (nargin > 2)
        %we have more initilizers --
        %recurse onto the next initializer, currying the initializer's
        %output with the body function.
        newbody = @(varargin) body(output{:}, varargin{:});
        require(varargin{2:end-1}, newbody);
    else
        %we have initialized everything - run the body
        body(output{:}); %run the curried, protected body
    end
catch
    err = lasterror;
    release();
    rethrow(err);
end
release();