function assertClose(what, towhat, logtolerance, abstolerance, varargin)
%function assertClose(what, towhat, logtolerance, abstolerance, varargin)

    if nargin < 4
        abstolerance = 0;
    end
    if nargin < 3
        logtolerance = 0.05;
    end

    assert( all( (abs(log10(what ./ towhat)) < logtolerance) | (abs(what - towhat) < abstolerance) ), varargin{:});
end