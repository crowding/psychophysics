function this = Trigger(varargin)
    %attempt at a more generic trigger mechanism Lightweight triggers are
    %not objects, but just functions so as to make for easier garbage
    %collecting. Probably won't work.

    triggers_ = cell(0,2);
    log = @noop;
    events = cell(0,2);
    
    persistent init__;
    this = autoobject(varargin{:});
    
    function setLog(s)
        log = s;
    end
        
    function singleshot(checker, fn)
        triggers_(end+1,:) = {@checkSingle, 1};
        
        function [t, k] = checkSingle(k)
            [t,k] = checker(k);
            if any(t)
                log('TRIGGER %s %s', func2str(fn), struct2str(k));
                fn(k);
                events(end+1,:) = {k.next, func2str(fn)};
            end
        end
    end

    function multishot(checker, fn)
        %adds a checker persistently. There is no removing other than by a
        %panic trigger.
        triggers_(end+1,:) = {@checkSingle, 0};
        
        function [t, k] = checkSingle(k)
            [t,k] = checker(k);
            if any(t)
                log('TRIGGER %s %s', func2str(fn), struct2str(k));
                fn(k);
                events(end+1,:) = {func2str(fn), k.next};
            end
        end
    end

    function panic(checker, fn)
        %adds a checker that will clear out all checkers including itself.
        triggers_(end+1,:) = {@checkSingle, 2};
                
        function [t, k] = checkSingle(k)
            [t,k] = checker(k);
            if any(t)
                log('TRIGGER %s %s', func2str(fn), struct2str(k));
                fn(k);
                events(end+1,:) = {k.next, func2str(fn)};
            end
        end
    end

    function mutex(varargin)
        %checks for one of several mutually exclusive conditions. 
        %Note, only single shot makes sense with this method. (think about
        %why-- for multishot or panics there is no effective difference.
        checkers = varargin(1:2:end);
        fns = varargin(2:2:numel(checkers) * 2);
        
        triggers_(end+1,:) = {@checkMutex, 1};
        
        function [t, k] = checkMutex(k)
            for i = 1:numel(checkers)
                [t, k] = checkers{i}(k);
                if any(t)
                    fns{i}(k);
                    log('TRIGGER %s %s', func2str(fns{i}), struct2str(k));
                    events(end+1,:) = {k.next, func2str(fn)};
                    break;
                end
            end
        end
    end

    function first(varargin)
        %In the case that multiple conditions prove true during a frame,
        %takes the first one and executes it, removing the trigger afterwards.
        %To accomplish this, each condition must have an associated time
        %coordinate.
        
        args = reshape(varargin, 3, []);
        
        triggers_(end+1,:) = {@runFirst, 1};
        
        function [ttr,k] = runFirst(k)
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
                log('TRIGGER %s %s', func2str(ffn), struct2str(k));
                events(end+1,:) = {k.triggerTime, func2str(ffn)};
            end
        end
    end


    function s = check(s)
        ndeleted = 0; %number deleted
        nt = size(triggers_, 1);
        for i = 1:size(triggers_, 1)
            ch = triggers_{i-ndeleted, 1};
            delete = triggers_{i-ndeleted, 2};

            [whether, s] = ch(s);

            if any(whether)
                if delete == 1
                    triggers_(i-ndeleted,:) = [];
                    ndeleted = ndeleted + 1;
                elseif delete == 2
                    %panic and delete all
                    triggers_(1:nt-ndeleted, :) = [];
                    return; %nothing more to do
                end
            end
        end
    end

    function [release, params] = init(params)
        events = cell(0,2);
        release = @noop;
    end

end