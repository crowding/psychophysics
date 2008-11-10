function this = Randomizer(varargin)
persistent subs__;
if isempty(subs__)
    subs__ = Sref();
end

base = MessageTrial('message', 'need a base trial!');

%usually we rely on the randomizer to place trials, but sometimes we also
%need blocks. Each of these must return success before the experiment
%proceeds.
startTrial = []; %shown at the beginning of the experiment
startTrialResult = [];
blockTrial = []; %shown at teh beginning of a "block"
blockTrialResults = {};
endBlockTrial = []; %shown at the end of a "block"
endBlockTrialResults = {};
endTrial = MessageTrial('message', 'Finished! Press space bar or knob to exit.'); %shown at the end of the experiment. Notice, there must be a trial here...
endTrialResults = [];

requireSuccess = 0; %do you require a 'success' to count as a trial in the block?

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

this = autoobject(varargin{:});

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

    function start()
        nextState_ = [];
    end

    function reset()
        if ~isempty(results)
            error('won''t throw results away!');
        end
        
        parameterColumns = {randomizers.subs};
        parameters = cell(0, numel(randomizers));
        startTrialResult = [];
        results = {};
        blockTrialResults = {};
        endBlockTrialResults = {};
        endTrialResult = [];
        start();
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

    function has = shuffleHasNext_()
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
    nextState_ = []; %the "state" of the experiment, or what kind of trial to give out next.
    resultState_ = []; %What to do on receiving a result.
    
    assignments_ = {};
    
    %There is a state machine for picking which trial to have next: a
    %shuffled trial, a special trial for the beginning of an experiment, a
    %special trial for the beginning of a block, a special trial for the
    %end of an experiment, a special trial for the end of a block, etc.
    function n = next(params)
        if isempty(nextState_)
            nextState_ = @startExperiment_;
            resultState_ = [];
        end
        
        n = nextState_(params);
    end

    function result(trial, result)
        %As a first step, look to see if there are any staircases etc to
        %assign...
        
        %assignments_ stores the raw assignments from the last trial, whiel
        %params_ stores the numeric values they evaluated to...
        %If the raw assignments are objects (generators, like staircase
        %functions) and have a 'results' method, then report back.
        
        resultState_(trial, result);
        
        if isfield(result, 'endTime') && isfield(base, 'startTime')
            base.startTime = result.endTime + interTrialInterval;
        else
            disp('ignoring inter trial interval');
        end
    end

    function next = startExperiment_(params)
        if isempty(startTrial)
            nextState_ = @startBlock_;
            next = nextState_(params);
        else
            resultState_ = @startExperimentResult_;
            next = startTrial;
        end
    end

    function startExperimentResult_(trial, result)
        if isSuccessful_(result)
            startTrialResult = result;
            nextState_ = @startBlock_;
        end
    end

    function next = startBlock_(params)
        if isempty(blockTrial)
            nextState_ = @regularTrial_;
            next = nextState_(params);
        else
            resultState_ = @startBlockResult_;
            next = blockTrial;
        end
    end

    blockCounter_ = 0;
    function startBlockResult_(trial, result)
        if isSuccessful_(result)
            blockTrialResults{end+1} = result;
            nextState_ = @regularTrial_;
            blockCounter_ = 0;
        end
    end

    function next = regularTrial_(params)
        %If the block is ending, end it...
        if blockCounter_ >= blockSize || ~shuffleHasNext_()
            nextState_ = @endBlock_;
            next = nextState_(params);
        else
            %pick the assignments and shuffle them...
            assignments_ = pick_();
            [base, params_] = assign_(base, assignments_, 'base');
            
            %unwrap because the rest of the apparatus uses the naked
            %object.
            next = unwrap(base);
            
            resultState_ = @regularTrialResult_;
        end
    end

    function regularTrialResult_(trial, result)
        %We got a trial back. Record the result...

        %for staircases, report thr result to our actual reporter, whether
        %or not successful.
        for i = 1:numel(assignments_)
            r = assignments_(i);
            
            if isstruct(r.values) && isfield(r.values, 'result') && isa(r.values.result, 'function_handle')
                r.values.result(trial, result, params_{i});
            elseif iscell(r.values)
                for j = 1:numel(r.subs)
                    if isstruct(r.values{j}) && isfield(r.values{j}, 'result') && isa(r.values.result{j}, 'function_handle')
                        r.values.result(trial, result, params_{i}{j}); %???
                    end
                end
            end
        end
        
        if isSuccessful_(result)
            results{end+1} = result;
            parameters(end+1,:) = params_;
            designOrder(end+1) = lastPicked_;
            if ~isnan(lastPicked_)
                designDone(lastPicked_) = true;
            end
            
            displayFunc(results);
            blockCounter_ = blockCounter_ + 1;

        elseif ~requireSuccess
            %don't record the result, but advance the block counter.
            blockCounter_ = blockCounter_ + 1;
        end
    end

    function next = endBlock_(params)
        if isempty(endBlockTrial)
            if shuffleHasNext_()
                nextState_ = @startBlock_;
            else
                nextState_ = @endExperiment_;
            end
            next = nextState_(params);
        else
            resultState_ = @endBlockResult_;
            next = endBlockTrial;
        end
    end

    function endBlockResult_(trial, result)
        if isSuccessful_(result)
            endBlockTrialResults{end+1} = result;
            if shuffleHasNext_()
                nextState_ = @startBlock_;
            else
                nextState_ = @endExperiment_;
            end
        end
    end

    function next = endExperiment_(params)
        if isempty(endTrial)
            next = [];
        else
            resultState_ = @endExperimentResult_;
            next = endTrial;
        end
    end

    function endExperimentResult_(trial, result)
        if isSuccessful_(result)
            endTrialResult = result;
        end
        nextState_ = @doneState_;
    end

    function next = doneState_(params)
        next = [];
    end

    function r = isSuccessful_(result)
        r = isfield(result, 'success') && (~isnan(result.success) && result.success) && (~isfield(result, 'abort') || ~result.abort);
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
            if iscell(item)
                out = item{ix};
            elseif numel(item) > 1
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