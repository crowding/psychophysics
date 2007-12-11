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
        triggers_(end+1,:) = {checker, fn, 1};
    end

    function multishot(checker, fn)
        %adds a checker persistently. There is no removing other than by a
        %panic function
        triggers_(end+1,:) = {checker, fn, 0};
    end

    function mutex(varargin)
        %checks for one of several mutually exclusive conditions. 
        %Note, only single shot makes sense with this method. (think about
        %why-- for multishot or panics there is no effective difference.
        checkers = varargin(1:2:end);
        fns = varargin(2:2:numel(checkers) * 2)
        triggers_(end+1,:) = {checkers, fns, 1};
    end

    function panic(checker, fn)
        %adds a checker that will clear out all checkers including itself.
        triggers_(end+1,:) = {checker, fn, 2};
    end

    function s = check(s)
        nd = 0; %number deleted
        for i = 1:size(triggers_, 1)
            ch = triggers_{i-nd, 1};
            fn = triggers_{i-nd, 2};
            delete = triggers_{i-nd, 3};
            
            if iscell(ch) %a mutex
                for j = 1:numel(ch)
                    mcheck = ch{j};
                    mfn = ch{j};
                    
                    [whether, s] = mcheck(s);
                    
                    if whether
                        mfn(s);
                        log_('TRIGGER %s %s', func2str(mfn), struct2str(s));
                        if delete == 1
                            triggers_{i,:} = [];
                            ndeleted = ndeleted + 1;
                        elseif delete == 2
                            %panic and delete all
                            triggers_ = cell(0,3);
                            return; %nothing more to do
                        end
                    end
                end
            else
                [whether, s] = ch(s);
                
                if whether
                    
                    fn(s);
                    log_('TRIGGER %s %s', func2str(fn), struct2str(s));
                    
                    if delete == 1
                        triggers_{i,:} = [];
                        ndeleted = ndeleted + 1;
                    elseif delete == 2
                        %panic and delete all
                        triggers_ = cell(0,3);
                        return; %nothing more to do
                    end
                end
            end
        end
    end


end