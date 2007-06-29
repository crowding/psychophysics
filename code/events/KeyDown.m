function this = KeyPress(varargin);
%Reacts to keys being pressed down.
last_ = false(size(getOutput(3, @kbCheck)));

evtable = cell(size(last_));

log = @noop;

this = autoobject(varargin{:});

%------methods------

    function check(k)
        now = k.keyCode;
        new = now &~last_;
        last_ = now;
        if any(new)
            k.pressed = new;
            %Now, I'd like to index the function pointers in last_ to pull out
            %every function that needs to be called. But since I don't know the
            %orientation of 'last' or 'evtable', it is unrelible in matlab to
            %do this. If evtable is a row vector, I'll get a row vector
            %indexing it, no matter how I index it. If it's some other shape, I
            %get the shape of the indexer. If the indexer is not a vector, i
            %get the shape of the indexer regardless. Note that this is in flat
            %contradiction to what is said in 'help punct.' (where it claims
            %that only row vectors will be retuirned when you index a vector by
            %a vector.)
            %
            %One could build a table of
            %all the special cases for indexing... asa a rhetorical tool.
            %In fact this would be a good rhetorical tool for lots of things,
            %so as to show how MATLAB is rather fucked up in its type system.
            k.keysPressed = KbName(new);
            for i = evtable(new)'
                if ~isempty(i{1})
                    log('KEY_DOWN $s $s', func2str(i{:}), struct2str(k));
                    i{1}(k);
                end
            end
        end
    end

    function set(fn, char)
        %sets a particular character as handler
        if nargin >= 2
            if ischar(char) | iscell(char) | islogical(char)
                evtable{KbName(char)} = deal(fn);
            elseif isnumeric(char)
                evtable{char} = deal(fn);
            end
        else
            [evtable{:}] = deal(fn);
        end
    end

    function unset(char)
        if (nargin == 0)
            [evtable{:}] = deal([]);
        elseif ischar(char) | iscell(char) | islogical(char)
            [evtable{KbName(char)}] = deal([]);
        elseif isnumeric(char)
            [evtable{char}] = deal([]);
        end
    end

    function [release, params] = init(params)
        release = @noop;
    end

end