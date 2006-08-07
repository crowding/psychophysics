function this = eyeEvents(el, calibration)
%function this = eyeEvents(el)
%
% Makes an object for tracking eye movements, and
% triggering calls when the eye moves in and out of screen-based regions.
%
% Constructor arguments:
%   'el' the eyelink constants
%
% complaint:
% (why pass around a bunch of constants as an argument?)

%----public interface----
this = public(...
    @update,...
    @add,...
    @remove,...
    @clear...
    );

%-----private data-----
lastx_ = [];
lasty_ = [];
lasttime_ = [];

%The event-oriented idea is based around a list of triggers. The
%lists specify a criterion that is to be met and a function to be
%called when the criterion is met.

%Array of trigger-interface objects. An advantage of closure-structs over
%matlab objects is that you can have an array containing diferent
%implementations of one interface.
triggers_ = cell(0);

%----- method definitions -----

    function update
        %Sample the eye
        [eyeX, eyeY, time] = eyeSample;
        
        %send the sample to each trigger and the triggers will fire if they
        %match
        cellfun(@(i) i.check(eyeX, eyeY, time), triggers_);
    end

    function add(trigger)
        %adds a trigger obeject.
        triggers_{end + 1} = trigger;
    end

    function remove(trigger)
        %Removes a trigger object.
        searchid = trigger.id();
        found = find(cellfun(@(x)x.id() == searchid, triggers_), 'UniformOutput', 0);
        triggers_{found(1)} = [];
    end

    function clear
        triggers{1:end} = [];
    end

    function [eyeX, eyeY, time] = eyeSample
        %obtain a new sample from the eye.
        connection = Eyelink('IsConnected');
        switch connection
            case el.connected
                %poll on the presence of a sample
                while Eyelink('NewFloatSampleAvailable') == 0;
                
                % FIXME: don't need to do this eyeAvailable check every
                % frame. Profile this.
                eye = Eyelink('EyeAvailable');
                switch eye
                    case el.BINOCULAR
                        error('eyeEvents:binocular',...
                            'don''t know which eye to use for events');
                    case el.LEFT
                        eyeidx = 1;
                    case el.RIGHT
                        eyeidx = 2;
                end

                sample = Eyelink('NewestFloatSample');
                [eyeX, eyeY, time] = deal(...
                    sample.gx(eye), sample.gy(eye), sample.time / 1000);
                [lastx_, lasty_, lasttime_] = deal(eyeX, eyeY, time);
        end
            case el.dummyconnected
                %use the mouse coordinates instead
                %
                %NB: mouse coordinates on dual head systems are not the
                %same as window coordinated when the
                %display is not the leftmost (Psychtoolbox issue)
                %
                %Complaint:
                %If Psychtoolbox interfaced with HID devices properly
                %(like, for isntance, pygame does) we would have an
                %interface to an event queue that would keep track of (and
                %timestamp!!!) all of our data for us without having to
                %loop (and possibly miss events between loops).
                %
                %Complaint:
                %meanwhile, we could avoid polling eyelink if its own event
                %code worked on OSX.
                [eyeX, eyeY] = GetMouse();
                time = GetSecs();

            otherwise
                error('eyeEvents:not_connected', 'eyelink not connected');
        end
    end
end