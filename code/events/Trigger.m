function this = Trigger(varargin)
    %attempt at a more generic trigger mechanism. Lightweight triggers are
    %not objects, but just functions. Keeps everything in persistent
    %variables with handles so as to make for less garbage collecting 
    %(Ugh...)

    persistent triggers_;
    persistent counter_;
    if isempty(triggers_)
        triggers_ = struct();
        counter_ = 0;
    end

    name = sprintf('t%d', counter_);
    triggers_.(name) = cell(0,4);
    counter_ = counter_ + 1;
    
    log = @noop;
    notlogged = {};
    events = cell(0,2);
    
    handlecounter_ = 1;
    
    persistent init__;
    this = autoobject(varargin{:});
    
    function setLog(s)
        log = s;
    end

    function reset()
        %cleanup to be recycled for the next trial...
        
        events = cell(0,2);
        notlogged = {};
        triggers_.(name) = cell(0,4);
    end

    function handle = singleshot(checker, fn)
        handle = handlecounter_;
        triggers_.(name)(end+1,:) = {@checkSingle_, 1, {checker, fn}, handlecounter_};
        handlecounter_ = handlecounter_+1;
    end

    function [t, k] = checkSingle_(k, checker, fn)
        [t,k] = checker(k);
        if any(t)
            log('TRIGGER %s %s', func2str(fn), struct2str(srmfield(k,notlogged)));
            fn(k);
            events(end+1,:) = {k.next, func2str(fn)};
        end
    end

    function handle = multishot(checker, fn)
        %adds a checker persistently. There is no removing other than by a
        %panic trigger.
        handle = handlecounter_;
        triggers_.(name)(end+1,:) = {@checkSingle_, 0, {checker, fn}, handlecounter_};
        handlecounter_ = handlecounter_+1;
    end


    function handle = panic(checker, fn)
        %adds a checker that will clear out all checkers including itself.
        handle = handlecounter_;
        triggers_.(name)(end+1,:) = {@checkSingle_, 2, {checker, fn}, handlecounter_};
        handlecounter_ = handlecounter_+1;
    end


    function handle = mutex(varargin)
        %checks for one of several mutually exclusive conditions. 
        %Note, only single shot makes sense with this method. (think about
        %why-- for multishot or panics there is no effective difference.
        checkers = varargin(1:2:end);
        fns = varargin(2:2:numel(checkers) * 2);
        
        handle = handlecounter_;
        triggers_.(name)(end+1,:) = {@checkMutex_, 1, {checkers, fns}, handlecounter_};
        handlecounter_ = handlecounter_+1;
    end

    function [t, k] = checkMutex_(k, checkers, fns)
        for i = 1:numel(checkers)
            [t, k] = checkers{i}(k);
            if any(t)
                fns{i}(k);
                log('TRIGGER %s %s', func2str(fns{i}), struct2str(srmfield(k,notlogged)));
                events(end+1,:) = {k.next, func2str(fns{i})};
                break;
            end
        end
    end

    function handle = first(varargin)
        %In the case that multiple conditions prove true during a frame,
        %takes the first one and executes it, removing the trigger afterwards.
        %To accomplish this, each condition must have an associated time
        %coordinate.
        
        args = reshape(varargin, 3, []);
        
        handle = handlecounter_;
        triggers_.(name)(end+1,:) = {@runFirst_, 1, {args}, handlecounter_};
        handlecounter_ = handlecounter_ + 1;
    end

    function [ttr,k] = runFirst_(k, args)
        tt = Inf;
        ii = Inf;
        ttr = [];
        ffn = [];
        for a = args
            [check, fn, timeindex] = a{:};
            [tr, k] = check(k);
            if any(tr)
                i = find(tr, 1, 'first');
                try
                    t = k.(timeindex)(i);
                catch
                    Screen('Flip', 10);
                    Screen('Flip', 10);
                    noop();
                end
                if t < tt
                    tt = t;
                    ttr = tr;
                    ii = i;
                    ffn = fn;
                end
            end
        end
        if ~isempty(ffn)
            k.triggerTime = tt;
            k.triggerIndex = ii;
            ffn(k);
            log('TRIGGER %s %s', func2str(ffn), struct2str(srmfield(k,notlogged)));
            events(end+1,:) = {k.triggerTime, func2str(ffn)};
        end
    end

    function s = check(s) %19368 calls, 32.881 sec on pastorianus
        
        triggers = triggers_.(name);
        ndeleted = 0; %number deleted
        
        nt = size(triggers, 1);
        for i = 1:size(triggers, 1)
            [ch, delete, args, handle] = triggers{i-ndeleted, :};
            if handle
                [whether, s] = ch(s, args{:});
                triggers = triggers_.(name); %checking can add a trigger to the end or mark deleted.
                
                if any(whether)
                    if delete == 1
                        triggers(i-ndeleted,:) = [];
                        ndeleted = ndeleted + 1;
                        triggers_.(name) = triggers;
                    elseif delete == 2
                        %panic and delete all
                        triggers_.(name) = triggers;
                        triggers(1:nt-ndeleted, :) = [];
                        triggers_.(name) = triggers;
                        break; %nothing more to do
                    end
                end
            else
                %checkers marked 0 are to be deleted.
                triggers(i-ndeleted,:) = [];
                ndeleted = ndeleted + 1;
                triggers_.(name) = triggers;
            end
        end
    end

    function removed = remove(handle)
        %deletes a trigger by its handle.
        %This just marks the trigger deleted. (by setting the handle equal to 0).
        %check() will actually delete them.
        triggers = triggers_.(name);
        deleted = zeros(1, size(triggers, 1));
        for i = handle(:)'
            deleted = deleted | [triggers{:,4}] == handle;
        end
        triggers(deleted,4) = {0};
        removed = sum(deleted);
        triggers_.(name) = triggers;
    end

    function [release, params] = init(params)
        events = cell(0,2);
        if ~isfield(triggers_, name)
            triggers_.(name) = cell(0,4);
        end
        
        %set the notlogged parameter to avoid logging some (tl;dr) fields.
        if isfield(params, 'notlogged')
            notlogged = params.notlogged;
        end
        
        release = @clear;
        
        function clear
            triggers_ = srmfield(triggers_, name);
        end
    end
end