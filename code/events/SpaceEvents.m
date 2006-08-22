function this = SpaceEvents(details_)
%base class for event managers that teack an object (mouse, eye) over
%time.

%-----public interface-----
this = public(@add, @remove, @update, @clear, @draw, @start, @stop, @sample);

%-----private data-----

%The event-oriented idea is based around a list of triggers. The
%lists specify a criterion that is to be met and a function to be
%called when the criterion is met.

%Array of trigger objects. An advantage of closure-structs over
%matlab objects is that you can have an array containing diferent
%implementations of one interface.
triggers_ = cell(0);

transform_ = transformToDegrees(details_.cal);
online_ = 0;

%----- methods -----

    function add(trigger)
        %adds a trigger object.
        triggers_{end + 1} = trigger;
    end

    function remove(trigger)
        %Removes a trigger object.
        searchid = trigger.id();
        found = find(cellfun(@(x)x.id() == searchid, triggers_));
        if ~isempty(found)
            triggers_(found(1)) = [];
        else
            disp huh;
        end
    end

    function clear
        triggers_(1:end) = []; %note use of parens and empty array even in
        %cell array--it's not a syntax, it's a special idiom.
    end

    function update
        %Sample the eye
        if online_
            error('spaceEvents:notOnline', 'must start spaceEvents before recording');
        end
        [x, y, t] = this.sample();
        [x, y] = transform_(x, y); %convert to degrees (native units)

        %send the sample to each trigger and the triggers will fire if they
        %match
        for trig = triggers_
            trig{:}.check(x, y, t);
        end
    end

    function draw(window, toPixels);
        %draw the triggers on the screen for debugging
        for trig = triggers_
            trig{:}.draw(window, toPixels);
        end
    end

    function start()
        online_ = 1;
    end

    function stop()
        online_ = 0;
    end

    function [x, y, t] = sample()
    end
end