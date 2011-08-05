function this = Randomizer(varargin)
persistent subs__;
if isempty(subs__)
    subs__ = Sref();
end

%speed bodges. With these we have to assume this object is a singleton. Oh
%god.
persistent base;
persistent startTrial;
persistent startTrialResult;
persistent blockTrial;
persistent blockTrialResults;
persistent endblockTrial;
persistent endblockTrialResults;
persistent endTrial;
persistent endTrialResults;
persistent randomizers;
persistent parameterColumns;
persistent parameters;
persistent results;
persistent design;
persistent displayFunc;
persistent seed;

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

randomizers = struct('subs', {}, 'values', {}, 'blocked', {});

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
organizedBlocks = [];
currentOrganizedBlock = 1;
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
            if requireSuccess
                n = blockSize * numBlocks - numel(results);
            else
                n = blockSize * (numBlocks - blocksCounter_) - blockCounter_;
            end
        end
    end

    function [ix, subs] = findix_(subs, require_present)
        if ~exist('require_present', 'var')
            require_present = 1;
        end
        
        if iscell(subs)
            subs = cellfun(@subsrefize_, subs, 'UniformOutput', 0);
        else
            subs = subsrefize_(subs);
        end
        
        found=false;
        for ix=1:numel(randomizers)
            if isequalwithequalnans(randomizers(ix).subs, subs)
                found = true;
                break
            end
        end
        
        if ~found
            if require_present
                error(['didn''t find the factor ' substruct2str(subs)]);
            else 
                ix = [];
            end
        end
    end

    function out = get(subs)
        out = randomizers(findix_(subs)).values;
    end

    function add(subs, values, blocked)
        %adds a randomizer, replacing if possible.
        if ~exist('blocked', 'var')
            blocked = 0;
        end
        replace(subs, values, 0, blocked);
    end

    function addBefore(before, subs, values, blocked)
        if ~exist('blocked', 'var')
            blocked = 0;
        end
        ix = findix_(before);
        randomizers((ix+1):(end+1)) = randomizers(ix:end);
        replaceWith(before, subs, values, 1, blocked);
    end

    function remove(subs)
        replace(subs, []);
    end

    function replace(subs, values, require_present, blocked)
        % replace an already set randomizer
        if ~exist('require_present', 'var')
            require_present = 1;
        end
        if ~exist('blocked', 'var')
            blocked = 0;
        end
        replaceWith(subs, subs, values, require_present, blocked)
    end

    function replaceWith(subs, newsubs, values, require_present, blocked)
        if ~exist('require_present', 'var')
            require_present = 1;
        end
        if ~exist('blocked', 'var')
            blocked = 0;
        end
        if ~isempty(results)
            error('won''t invalidate results!');
        end
        
        [ix, subs] = findix_(subs,require_present);
        if iscell(newsubs)
            newsubs = cellfun(@subsrefize_, newsubs, 'UniformOutput', 0);
        else
            newsubs = subsrefize_(newsubs);
        end

        if isempty(ix)
            ix = numel(randomizers) + 1;
        end
        
        if isempty(values)
            randomizers(ix) = [];
        else
            randomizers(ix)= struct('subs', {newsubs}, 'values', {values}, 'blocked', blocked);
        end
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
        blockCounter_ = 0;
        blocksCounter_ = 0;
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
        if ~isa(b, 'Obj')
            base = Obj(b);
        else
            base = b;
        end
    end

    function has = shuffleHasNext_()
        if requireSuccess
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
        else
            if numLeft() > 0
                has = 1;
            else
                has = 0;
            end
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
    savedParams_ = [];
    function n = next(params)
        if isempty(nextState_)
            nextState_ = @startExperiment_;
            resultState_ = [];
        end
        
        savedParams_ = params;
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
            st = result.endTime + interTrialInterval;
            base.startTime = st; 
            fprintf('starting at %g\n', st);
        else
            disp('ignoring inter trial interval');
        end
    end

    blocksCounter_ = 0;
    function next = startExperiment_(params)
        blocksCounter_ = 0;
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
            blockCounter_ = 0;
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
                    if isstruct(r.values{j}) && isfield(r.values{j}, 'result') && isa(r.values{j}.result, 'function_handle')
                        r.values{j}.result(trial, result, params_{i}{j}); %???
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
            
            displayFunc(savedParams_, results);
            blockCounter_ = blockCounter_ + 1;

        elseif ~requireSuccess
            %don't record the result, but advance the block counter.
            blockCounter_ = blockCounter_ + 1;
        end
    end

    function next = endBlock_(params)
        blocksCounter_ = blocksCounter_ + 1;
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
        %organize into blocks
        thisBlock = min(organizedBlocks(~designDone));
        
        which = find(~designDone & organizedBlocks == thisBlock);
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
        
        %fun MATLAB fact! If you are in the debugger and try issuing the
        %following command, it will fail because "Attempt to add "%U35" to
        %a static workspace!
        [~,~,organizedBlocks] = unique(design(:,logical([randomizers.blocked])), 'rows');
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
                if numel(r.subs) ~= numel(val)
                    error('Randomizer:badAssignment'...
                        , '%d subscripts given for parallel assignment but only %d values. First subscript was ''%s'''...
                        , numel(r.subs), numel(val), substruct2str(r.subs{1}));
                end
                for j = 1:numel(r.subs)
                    try
                        v = ev(val{j}, object);
                    catch
                        e = lasterror;
                        e.message = sprintf('Error evaluating %s = %s :\n%s', substruct2str(r.subs{j}), evalc('disp(val{j})'), e.message);
                        rethrow(e);
                    end
                    if ~isstruct(v)
                        dump(v, @printf, [name substruct2str(r.subs{j})]);
                    end
                    try
                        object = subsasgn(object, r.subs{j}, v);
                    catch
                        %add some descriptive detail of what you were trying to do
                        e = lasterror;
                        e.message = sprintf('Error assigning %s = %s :\n%s', substruct2str(r.subs{j}), evalc('disp(v)'), e.message);
                        rethrow(e);
                    end
                    val{j} = v;
                end
            else
                val = ev(val, object);
                if ~isstruct(val)
                    dump(val, @printf, [name substruct2str(r.subs)]);
                end
                if ~isempty(r.subs)
                    try
                        object = subsasgn(object, r.subs, val);
                    catch
                        %add some descriptive detail of what you were trying to do
                        e = lasterror;
                        e.message = sprintf('Error assigning %s = %s :\n%s', substruct2str(r.subs), evalc('disp(v)'), e.message);
                        rethrow(e);
                    end
                else
                    object = val;
                    %special case: this wholesale reassignment is not
                    %recorded.
                    val = [];
                end
            end
            params{i} = val;
        end
    end

end