function s = structcat(varargin)
    %take a cell array(s) of structs, and concatenate them into a regular
    %array of structs with the union of all fields.
    
    if nargin == 1 && iscell(varargin{1})
        varargin = {varargin{1}{:}};
    end
    
    fnames = cellfun(@fieldnames, varargin, 'UniformOutput', 0);
    fnames = unique(cat(1, fnames{:}, {}));
    varargin = cellfun(@(i) i(:), varargin, 'UniformOutput', 0);

    for i = 1:numel(fnames)
        for j = 1:numel(varargin)
            if ~isfield(varargin{j}, fnames{i})
                [varargin{j}(:).(fnames{i})] = deal([]);
            end
        end
    end

    s = cat(1, varargin{:});
end