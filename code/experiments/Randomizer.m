function this = Randomizer(varargin)
persistent subs__;
if isempty(subs__)
    subs__ = Sref();
end

base = MessageTrial('message', 'need a base trial!');
randomizations = struct('subs', {}, 'values', {});
parameterColumns = {}; %the substructs corresponding to the parameter columns.
parameters = {}; %a history of the trial parameters.
results = {}; %store a history of the trial results.

persistent init__;
this = autoobject(varargin{:});

    function add(subs, values)
        %adds a randomization.

        if iscell(subs)
            subs = cellfun(@subsrefize, subs, 'UniformOutput', 0);
        else
            subs = subsrefize(subs);
        end

        if ~iscell(values) && ~isa(values, 'function_handle')
            error('Randomizer:invalidValues', 'Improper values');
        end
        
        randomizations(end + 1) = struct('subs', {subs}, 'values', {values});
        reset();
    end

    function subs = subsrefize(subs)
        if ischar(subs)
            %convert to a substruct...
            try
                subs = eval(sprintf('(subs__.%s);', subs));
            catch
                errorcause(lasterror, 'Randomizer:invalidSubscript', 'Invalid subscript reference ".%s"', subs);
            end
        end

        %check that you actually have a substruct
        try
            subs = subsref(subs__, subs);
        catch
            errorcause(lasterror, 'Randomizer:invalidSubscript', 'Improper substruct');
        end
    end

    function reset()
        if ~isempty(results)
            error('won''t throw results away!');
        end
        
        parameterColumns = {randomizations.subs};
        parameters = cell(0, numel(randomizations));
        results = {};
    end

    function setRandomizations(rands)
        error('Randomizer:ReadOnlyValue', 'that''s a read-only-value for now');
    end

    function setBase(b)
        if ~isa(b, 'obj')
            base = Obj(b);
        else
            base = b;
        end
    end

    function has = hasNext()
        has = 1;
    end

    params_ = {};
    function n = next(params)
        %randomize according to plan...
        params_ = cell(1, numel(randomizations));
        for i = 1:numel(randomizations(:)')
            r = randomizations(i);
            if iscell(r.values)
                val = randsample(r.values(:), 1);
                val = val{1};
            elseif isa(r.values, 'function_handle')
                fn = r.values;
                if nargin(fn) == 0
                    val = fn();
                else
                    val = fn(base);
                end
            end
            if iscell(r.subs)
                for i = 1:numel(r.subs)
                    fprintf('base%s = %s\n', substruct2str(r.subs{i}), smallmat2str(val{i}));
                    base = subsasgn(base, r.subs{i}, val{i});
                end
            else
                fprintf('base%s = %s\n', substruct2str(r.subs), smallmat2str(val));
                base = subsasgn(base, r.subs, val);
            end
            params_{i} = val();
        end
        
        %unwrap because the rest of the apparatus uses the naked object
        n = unwrap(base);
    end

    function result(trial, result)
        results{end+1} = result;
        parameters(end+1,:) = params_;
    end
end