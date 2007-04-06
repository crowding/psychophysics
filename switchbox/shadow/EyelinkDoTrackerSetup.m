function result = EyelinkDoTrackerSetup(el, varargin)
    %this is an adaptation for the Ocean Matrix switchbox;
    %it switches the monitor to and from the eyelink as necessary.
    
    %Inside the regular EyelinkDoTrackerSetup function, we want to redirect
    %the Eyelink function to snoop on the target displays. Do this by
    %mucking with the path: add in an "Eyelink" wrapper. THe eyelink
    %wrapper intercepts eyelink mode requests and switches the display on
    %transition.
    dir = fileparts(mfilename('fullpath'));
    
    require(getswitchbox()...
           , tempaddpath('addpath', fullfile(dir, 'wrapper'))...
           , temprmpath('rmpath', dir)...
           , @doit);
       
    function doit(params)
        global switchbox___;
        switchbox___ = params;
        result = EyelinkDoTrackerSetup(el, varargin{:});
        params.switchin();
    end

end