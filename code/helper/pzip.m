function out = pzip(varargin)
%like python zip

varargin = cellfun(@box, varargin, 'UniformOutput', 0);

out = cellfun(@(varargin) {varargin{:}}, varargin{:}, 'UniformOutput', 0);
end

function c = box(c)
    if ~iscell(c)
         c = num2cell(c);
    end
end