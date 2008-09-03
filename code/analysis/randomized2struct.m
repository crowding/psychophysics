function [parameters, results, design] = randomized2struct(trials)
    paramNames = parameterColumnNames(trials.parameterColumns);
    
    %some of them will be cells
    parameters = params2struct(paramNames, trials.parameters);
    results = cat(1, trials.results{:});
    design = trials.design(trials.designOrder,:);
end

function out = parameterColumnNames(c)
    if iscell(c)
        if all(cellfun(@isstruct, c))
            out = parameterColumnNames(cat(2, c{:}));
        else
            out = cellfun(@parameterColumnNames, c, 'UniformOutput', 0);
        end
    else
        ix = find(strcmp('.', {c.type}), 1, 'last');
        out = c(ix).subs;
    end
end

function out = params2struct(names, params)
    params = mat2cell(params, size(params,1), ones(1,size(params, 2)));
    x = cellfun(@param2struct, names, params, 'UniformOutput', 0);
    out = structunion(x{:});
end

function out = param2struct(name, param)
    if iscell(name)
        param = cat(1, param{:});
        out = params2struct(name, param);
    else
        out = struct(name, param);
    end
end