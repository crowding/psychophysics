function this = Trigger(varargin)
    %attempt at a more generic trigger mechanism Lightweight triggers are
    %not objects, but just functions so as to make for easier garbage
    %collecting. Probably won't work.

    triggers_ = cell(0,3);
    log = @noop;
    
    persistent init__;
    this = autoobject(varargin{:});
    
    function setLog(s)
        log = s;
    end
        
    function singleshot(checker, fn)
        triggers_(end+1,:) = {runSingle_(checker, fn), 1};
    end

    function multishot(checker, fn)
        %adds a checker persistently. There is no removing other than by a
        %panic trigger.
        triggers_(end+1,:) = {runSingle_(checker, fn), 0};
    end

    function mutex(varargin)
        %checks for one of several mutually exclusive conditions. 
        %Note, only single shot makes sense with this method. (think about
        %why-- for multishot or panics there is no effective difference.
        checkers = varargin(1:2:end);
        fns = varargin(2:2:numel(checkers) * 2);
        triggers_(end+1,:) = {runMultiple_(checkers, fns), 1};
    end

    function panic(checker, fn)
        %adds a checker that will clear out all checkers including itself.
        triggers_(end+1,:) = {runSingle_(checker, fn), 2};
    end

    function first(varargin)
        %In the case that multiple conditions prove true furing a frame,
        %takes the first one and executes it, removing itself afterwards.
        %To accomplish this, each condition must have an associated time
        %coordinate.
        error('not written');
    end

    function c = runMultiple_(checkers, fns)
        c = @f;
        function [t, k] = f(k)
            for i = 1:numel(checkers)
                [t, k] = checkers{i}(k);
                if any(t)
                    log('TRIGGER %s %s', func2str(fns{i}), struct2str(k));
                    fns{i}(k);
                end
            end
        end
    end

    function c = runSingle_(checker, fn)
        c = @f;
        function [t, k] = f(k)
            [t,k] = checker(k)
            if any(t)
                log('TRIGGER %s %s', func2str(fns{i}), struct2str(k));
                k = fn(k);
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
        release = @noop;
    end

end