function this = KeyDown(fn, char, varargin)
%function this = KeyDown(fn, char);
%Reacts to keys being pressed down.
%fn = a function to call;
%char = the keycode or name of the key;
%
%This can support listening to multiple keys. Just call set(fn, char) for
%each key to listen to. Call set(fn) to set the function on all keys.
%Call unset() to clear event handlers or unset(char) to clear from a
%particular character.

last_ = false(size(getOutput(3, @KbCheck)));
evtable = cell(size(last_));

log = @noop;

persistent init__;
this = autoobject(varargin{:});

if nargin >= 2
    set(fn, char);
elseif nargin >= 1
    set(fn);
end

%------methods------

    function check(k)
        now = k.keycodes;
        
        new = now(~last_(now));
        last_(new) = 1;
        last_(~new) = 0;
        
        if any(new)
            k.pressed = 1;
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
            %all the special cases for indexing... as a rhetorical tool.
            %In fact this would be a good rhetorical tool for lots of things,
            %so as to show how MATLAB is rather fucked up in its type system.
            k.keysPressed = new;
            for i = evtable(new)'
                if ~isempty(i{1})
                    log('TRIGGER %s %s', func2str(i{:}), struct2str(k));
                    i{1}(k);
                end
            end
        end
    end

    function set(fn, char)
        %sets a particular character as handler
        if nargin >= 2
            if isnumeric(char)
                evtable{char} = deal(fn);    
            elseif ischar(char) | iscell(char) | islogical(char)
                if iscell(fn)
                    [evtable{KbName(char)}] = fn{:};
                else
                    [evtable{KbName(char)}] = deal(fn);
                end
            else
                error('KeyDown:badarg', 'bad argument');
            end
        else
            [evtable{:}] = deal(fn);
        end
    end

    function unset(char)
        if (nargin == 0)
            [evtable{:}] = deal([]);
        elseif isnumeric(char)
            [evtable{char}] = deal([]);
        elseif ischar(char) | iscell(char) | islogical(char)
            [evtable{KbName(char)}] = deal([]);
        end
    end

    function [release, params] = init(params)
        release = @noop;
    end

end