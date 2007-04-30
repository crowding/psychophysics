% dump data out as a string.
function out = dumpstring(data, name)

if ~exist('name', 'var')
    name = inputname(1);
    if isempty(name)
        name = 'ans';
    end
end

strings = {};

function addstring(varargin)
    strings{end+1} = sprintf(varargin{:});
end

dump(data, @addstring, name);

out = join(' ', strings);
out = regexprep(out, '[\r\n]', '');

end
