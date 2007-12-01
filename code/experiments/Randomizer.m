function this = Randomizer(varargin)
persistent subs__;
if isempty(subs__)
    subs__ = Sref();
end

base = MessageTrial('message', 'need a base trial!');
blockTrial = MessageTrial('message', 'beginning of block');
randomizers = struct('subs', {}, 'values', {});

parameterColumns = {}; %the substructs corresponding to the parameter columns.
parameters = {}; %a history of the trial parameters that were assigned.
results = {}; %a history of the trial results.
blockSize = 10;
numBlocks = Inf;
interTrialInterval = 0.5;

%full factorial designs are harder, this should be factored into a
%different class actually.
fullFactorial = 0;
design = {};
designDone = [];
designOrder = [];

persistent init__;

this = Obj(autoobject(varargin{:}));

    function add(subs, values)
        %adds a randomizer.
        if ~isempty(results)
            error('won''t invalidate results!');
        end

        if iscell(subs)
            subs = cellfun(@subsrefize_, subs, 'UniformOutput', 0);
        else
            subs = subsrefize_(subs);
        end

        if ~iscell(values) && ~isa(values, 'function_handle')
            error('Randomizer:invalidValues', 'Improper values');
        end
        
        randomizers(end + 1) = struct('subs', {subs}, 'values', {values});
        reset();
    end

    function subs = subsrefize_(subs)
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
        
        parameterColumns = {randomizers.subs};
        parameters = cell(0, numel(randomizers));
        results = {};
    end

    function setRandomizers(rands)
        error('Randomizer:ReadOnlyValue', 'that''s a read-only-value for now');
    end

    function setBase(b)
        if ~isa(b, 'obj')
            base = Obj(b);
        else
            base = b;
        end
    end

    function has = hasNext(last, result)
        if numel(results) < blockSize * numBlocks
            if fullFactorial
                if isempty(results)
                    shuffle_();
                end
                has = any(~designDone);
            else
                has = 1;
            end
        else
            has = 0;
        end
    end

    params_ = {}; %the last params that were uaed in assignment
    wasblock_ = 0;
    function n = next(params)
        %randomize according to plan...
        if mod(numel(results), blockSize) == 0 && ~wasblock_
            n = blockTrial;
            params_ = {};
            wasblock_ = 1;
        else
            assignments = pick_();
            [base, params_] = assign_(base, assignments, 'base');
            
            %unwrap because the rest of the apparatus uses the naked object
            n = unwrap(base);
            wasblock_ = 0;
        end
    end

    function result(trial, result)
        if ~isfield(result, 'success') || result.success
            if ~wasblock_
                results{end+1} = result;
                parameters(end+1,:) = params_;
                if fullFactorial
                    designDone(lastPicked_) = true;
                end
            end
            %here is where you do can fit in staircasing by a
            %similar mechanism (TODO)...
        end
        
        if isfield(result, 'endTime') && isfield(base, 'startTime')
            base.startTime = result.endTime + interTrialInterval;
        else
            disp('ignoring inter trial interval');
        end
    end


    function params = pick_()
        if fullFactorial
            params = pickWithoutReplacing();
        else
            params = pickReplacing_();
        end
    end

    function params = pickReplacing_()
        s = cellfun('prodofsize', {randomizers.values});
        indices = ceil(rand(size(s)) .* s);
        p = select_({randomizers.values}, indices);
        params = randomizers;
        [params.values] = deal(p{:});
    end

    lastPicked_ = []; %the last item we picked...
    function params = pickWithoutReplacing_()
        which = find(~designDone);
        ix = ceil(rand*numel(which));
        lastPicked_ = which(ix);
        params = design(lastPicked_, :);
    end
    
    function shuffle_()
        r = randomizers(:,2)';
        d = fullfact(cellfun('prodofsize', r));
        design = cellfun(@(indices)select_(randomizers(:,1)', indices)...
            , mat2cell(d, ones(size(d,1),1), size(d,2)), 'UniformOutput', 0);
        designDone = false(size(design, 1), 1);
    end
    
    function out = select_(list, indices)
        %note we have to avoid invoking function handles, so we avoid
        %subscripting any scalar.
        out = cellfun(@pick, list, num2cell(indices), 'UniformOutput', 0);
        
        function out = pick(item, ix)
            if numel(item) > 1
                out = item(ix);
            else
                out = item;
            end
        end
    end

    function [base, params] = assign_(object, assignments, name)
        params = cell(1, numel(assignments));
        for i = 1:numel(assignments)

            r = assignments(i);
            val = r.values;
            
            if isa(r.values, 'function_handle')
                fn = r.values;
                
                if nargin(fn) == 0
                    val = fn();
                else
                    val = fn(object);
                end
            end
            
            if iscell(r.subs)
                for j = 1:numel(r.subs)
                    dump(val{i}, @fprintf, [name substruct2str(r.subs{j})]);
                    object = subsasgn(object, r.subs{j}, val{j});
                end
            else
                dump(val, @fprintf, [name substruct2str(r.subs)]);
                base = subsasgn(base, r.subs, val);
            end
            params{i} = val;
        end
    end

end