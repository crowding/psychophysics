function this = Randomizer(varargin)
persistent subs__;
if isempty(subs__)
    subs__ = Sref();
end

base = MessageTrial('message', 'need a base trial!');
blockTrial = [];
randomizers = struct('subs', {}, 'values', {});

parameterColumns = {}; %the substructs corresponding to the parameter columns.
parameters = {}; %a history of the trial parameters that were assigned.
results = {}; %a history of the trial results.
blockSize = Inf;
numBlocks = Inf;
interTrialInterval = 0.5;

%full factorial designs have to maintain a bunch of state and are harder;
%this should be factored into a different class. Also it's a very good
%application for using continuations in a language that supports that.
fullFactorial = 0;
reps = 1;
design = {};
designDone = [];
designOrder = [];
displayFunc = @noop; %called after every successful trial....
seed = randseed();

persistent init__;

this = Obj(autoobject(varargin{:}));

    function n = blocksLeft()
        checkShuffle_();
        if fullFactorial
            n = ceil(numLeft() / blockSize());
        else
            n = ceil(numLeft() / blockSize());
        end
    end

    function n = numLeft()
        checkShuffle_();
        if fullFactorial 
            n = sum(~designDone);
        else
            n = blockSize * numBlocks - numel(results);
        end
    end

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
        error('not implemented');
        if ~isempty(results)
            error('won''t invalidate results!');
        end
%{
        %make sure things are in struct format
        rands = orderfields(rands, {'subs', 'values'});
        
        %normalize subscripts
        rands = arrayfun(@checkvalues,{rands.subs});
        function r = checksubs(r)
            if iscell(r.subs) && iscell(r.values)
                r.subs = cellfun(@subsrefize_, r.subs, 'UniformOutput', 0);
                if ~isequal(size(r.subs), size(r.values)
                    error('Randomizer:invalidRandomizers', 'one of subscript and value si a cell but the other is not');

                end
            elseif ~iscell(r.values) && iscell(r.values)
                sub = {subsrefize_(subs)};
                r.values = {r.values};
            else
                error('Randomizer:invalidRandomizers', 'value is a cell but subscriptis not');
            end
            if size(r.sub, r.value)
                
            end
        end
        
        %normalize values
        [rands.values] = cell2outputs(cellfun(@checkvalues,{rands.subs}));
        %}
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
                checkShuffle_();
                has = any(~designDone);
            else
                has = 1;
            end
        else
            has = 0;
        end
    end

    function checkShuffle_()
        if fullFactorial && (isempty(results) || isempty(design))
            shuffle_();
        end
    end

    params_ = {}; %the last params that were uaed in assignment
    
    %state for blocking
    lastblock_ = NaN; %what was the last block trial we sent?
    wasblock_ = 0; %did we just send out a block trial?
    assignments_ = {};
    
    function n = next(params)
        assert(logical(hasNext()));
        %randomize according to plan...
        if mod(numel(results), blockSize) == 0 && (lastblock_ ~= numel(results)) && ~isempty(blockTrial);
            n = blockTrial;
            params_ = {};
            lastblock_ = numel(results);
            wasblock_ = 1;
        else
            wasblock_ = 0;
            assignments_ = pick_();
            [base, params_] = assign_(base, assignments_, 'base');
            
            %unwrap because the rest of the apparatus uses the naked object
            n = unwrap(base);
        end
    end

    function result(trial, result)
        %As a first step, look to see if there are any staircases etc to
        %assign...
        
        %assignments_ stores the raw assignments from the last trial.
        %If the raw assignments are objects and have a 'results' method,
        %then assign them...
        for i = 1:numel(assignments_)
            r = assignments_(i);
            
            if isstruct(r.values) && isfield(r.values, 'result') && isa(r.values.result, 'function_handle')
                r.values.result(trial, result);
            elseif iscell(r.values)
                for j = 1:numel(r.subs)
                    if isstruct(r.values{i}) && isfield(r.values{i}, 'result') && isa(r.values.result{i}, 'function_handle')
                        r.values{i}.result(trial, result);
                    end
                end
            end
        end
        
        if (~isfield(result, 'success') || result.success) && (~isfield(result, 'abort') || ~result.abort);
            if ~wasblock_
                results{end+1} = result;
                parameters(end+1,:) = params_;
                designOrder(end+1) = lastPicked_;
                if ~isnan(lastPicked_)
                    designDone(lastPicked_) = true;
                end
                
                %here is where you do can fit in staircasing by a
                %similar mechanism (TODO)...
                displayFunc(results);
            end
        end
        
        if isfield(result, 'endTime') && isfield(base, 'startTime')
            base.startTime = result.endTime + interTrialInterval;
        else
            disp('ignoring inter trial interval');
        end
    end


    function params = pick_()
        if fullFactorial
            params = pickWithoutReplacing_();
        else
            params = pickReplacing_();
        end
    end

    function params = pickReplacing_()
        s = cellfun('prodofsize', {randomizers.values});
        rand('twister', seed);
        indices = ceil(rand(size(s)) .* s);
        seed = rand('twister');
        
        p = select_({randomizers.values}, indices);
        params = randomizers;
        
        %"a dot name structure assignment is illegal when the structure is
        %empty." Why, MATLAB, can't you do the obvious thing, i.e. nothing?
        if ~isempty(p)
            [params.values] = deal(p{:});
        end
        lastPicked_ = NaN;
    end

    lastPicked_ = NaN; %the last item we picked...
    function params = pickWithoutReplacing_()
        which = find(~designDone);
        rand('twister', seed);
        ix = ceil(rand*numel(which));
        seed = rand('twister');
        indices = design(which(ix), :);
        
        p = select_({randomizers.values}, indices);
        params = randomizers;
        [params.values] = deal(p{:});
        lastPicked_ = which(ix);
    end
    
    function shuffle_()
        r = {randomizers.values};
        design = fullfact(cellfun('prodofsize', r));
        design = repmat(design, reps, 1);
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

    function [object, params] = assign_(object, assignments, name)
        params = cell(1, numel(assignments));
        for i = 1:numel(assignments)

            r = assignments(i);
            val = ev(r.values, object);
            
            if iscell(r.subs)
                for j = 1:numel(r.subs)
                    try
                    v = ev(val{j}, object);
                    catch
                        rethrow(lasterror);
                    end
                    dump(v, @printf, [name substruct2str(r.subs{j})]);
                    object = subsasgn(object, r.subs{j}, v);
                end
            else
                v = ev(val, object);
                dump(v, @printf, [name substruct2str(r.subs)]);
                object = subsasgn(object, r.subs, v);
            end
            params{i} = val;
        end
    end

end