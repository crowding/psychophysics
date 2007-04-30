function fail(message, varargin)
%What to call to fail a test. Takes arguments like sprintf();
e.identifier = 'assert:assertionFailed';
if exist('message', 'var')
    e.message = sprintf(message, varargin{:});
end
error(e);
