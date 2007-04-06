function varargout = Eyelink(command, varargin)
%If you are seeing this under ordinary circumstances you have your path
%set wrong...
%
%This is a wrapper function for within EyelinkDoTrackerSetup, which
%switches the monitor input as necessary.
    allEyelinks = which('Eyelink','-ALL');
    dir = fileparts(allEyelinks{2});

    no = nargout;
    out = {};
    args = varargin;

    require(tempcd('dir', dir), @callit);
    function callit(params)
        global switchbox___;
        persistent mode__;
        persistent target__;
        persistent on__;
        persistent laston__
        
        if isempty(mode__)
            mode__ = 0;
            target__ = 0;
            laston__ = 0;
            on__ = 0;
        end
        
        [output{1:no}] = Eyelink(command, args{:});
        out = output;
        
        if strcmpi(command, 'currentmode')
            mode__ = out{1};
        elseif strcmpi(command, 'targetcheck');
            target__ = out{1};
        end
        
        on = bitand(mode__,8) & target__;
        if on
            laston__ = GetSecs();
        end
        
        if on && ~on__
            switchbox___.switchin();
            on__ = 1;
        elseif ~on && on__
            if (~bitand(mode__,8)) || (GetSecs() - laston__ > 0.5)
                switchbox___.switchout();
                on__ = 0;
            end
        end
    end
    varargout = out;
end