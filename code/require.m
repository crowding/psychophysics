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
%Simple example usage, uses RESOURCE to generate the function handles
%
%   require(resource(@fopen, @fclose, 'out.txt', 'W'), @write);
%   function write(fid)
%       fprintf(fid, 'Hello world!\n');
%   end
%
%Here is an example of usage without 'resource'. 
%
%   require(@opener, @write);
%   function write(fid)
%       fprintf(fid, 'Hello world!\n');
%   end
%
%   function r = opener
%       num = fopen(filename)
%      if fid < -1
%           error('could not open file');
%     r = @()close(fn);
%   end