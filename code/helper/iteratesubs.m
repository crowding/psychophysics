function [subs, enums] = iteratesubs(s, prefix)
    %produce a list of substructs for use with SUBSREF, that iterate
    %through the argument in order. S must be a cell array or struct.
    if nargin < 2
        prefix = struct('type', {}, 'subs', {});
    end

    if iscell(s)
        subs = cell(1, numel(s));
        enums = cell(1, numel(s));
        for i = 1:numel(s)
            [subs{i}, enums{i}] = iteratesubs...
                ( s{i}...
                , [prefix struct('type', '{}', 'subs', {{i}})] ...
                );
        end
        subs = cat(1, subs{:});
        enums = cat(1, enums{:});
    elseif isstruct(s)
        if isfield(s, 'enum_')
            subs = {[prefix struct('type', '.', 'subs', {{'enum_'}})]};
            enums = {struct('s', [prefix], 'enum', s)};
        else
            names = fieldnames(s);
            subs = cell(1, numel(s) * numel(names));
            enums = cell(1, numel(s) * numel(names));
            for ii = 1:numel(s)
                for i = 1:numel(names)
                    [subs{(ii-1)*numel(names)+i},enums{(ii-1)*numel(names)+i}] = iteratesubs...
                        ( s(ii).(names{i})...
                        , [prefix struct('type', {'()', '.'}, 'subs', {{ii} names{i}})] ...
                        );
                end
            end
            subs = cat(1, subs{:});
            enums = cat(1, enums{:});
        end
    else
        subs = {prefix};
        enums = {};
    end
end