function errorcause(cause, varargin)

try
    error(varargin{:});
catch
    e = lasterror;
    e.stack(1) = [];
    rethrow(adderror(e, cause));
end
error('errorcause:wtf', 'Should not get here!');