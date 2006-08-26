function this = SpaceEvents()
%base class for event managers that track a @-D spatial input (e.g. mouse,
%eye) over time.

%-----public interface-----
this = public(@add, @remove, @update, @clear, @draw, @initializer, @sample);

%-----private data-----

%The event-oriented idea is based around a list of triggers. The
%lists specify a criterion that is to be met and a function to be
%called when the criterion is met.

%there are alternatives for how to maintain the trigger list. The
%datatype of the list appears to be a source of much overhead when calling
%update. Right now the middle alternative seems fastest, for whatever
%reason.

%triggers_ = cell(0); %ideal
triggers_ = struct('id', {}, 'check', {}, 'draw', {}); %middle
%check_ = emptyOf(@(x)0); %ugly
%draw_ = emptyOf(@(x)0); %ugly
%id_ = []; %ugly

transform_ = [];
online_ = 0;

%----- methods -----

    function add(trigger)
        %adds a trigger object.
        %
        %See also Trigger.
        
        %triggers_{end + 1} = trigger; %ideal
        triggers_(end+1) = interface(trigger, triggers_); %middle
        %check_(end+1) = trigger.check; %ugly
        %draw_(end+1) = trigger.draw; %ugly
        %id_(end+1) = trigger.id(); %ugly
    end

    function remove(trigger)
        %Removes a trigger object.
        %
        %See also Trigger.
        
        searchid = trigger.id();
        %found = find(cellfun(@(x)x.id() == searchid, triggers_)); %ideal
        found = find(arrayfun(@(x)x.id() == searchid, triggers_)); %middle
        %found = find(id_ == searchid); %ugly
        if ~isempty(found)
            %triggers_(found(1)) = []; %ideal
            triggers_(found(1)) = []; %middle
            %check_(found(1)) = []; %ugly
            %draw_(found(1)) = []; %ugly
            %id_(found(1)) = []; %ugly
        else
            warning('SpaceEvents:noSuchItem',...
                'tried to remove nonexistent item with id %d', searchid);
        end
    end

    function clear
        %Removes all triggers.
        
        %The use of () and [] even when clearing out a 
        %cell array--it's not a general syntax, it's a special idiom. it
        %preserves the array type.

        %triggers_(:) = []; %ideal
        triggers_(:) = []; %middle
        
        %check_(:) = []; %ugly
        %draw_(:) = []; %ugly
        %id_(:) = []; %ugly
    end

    function update(next)
        % Sample the eye and give to sample to all triggers.
        %
        % next: the scheduled next refresh.
        %
        % See also SpaceEvents>sample, Trigger>check.
        
        if ~online_
            error('spaceEvents:notOnline', 'must start spaceEvents before recording');
        end
        [x, y, t] = this.sample();
        [x, y] = transform_(x, y); %convert to degrees (native units)

        %send the sample to each trigger and the triggers will fire if they
        %match
        
        for trig = triggers_ %ideal, middle
        %for check = check_ %ugly
            %trig{:}.check(x, y, t, next); %ideal
            trig.check(x, y, t, next); %middle
            %check(x, y, t, next); %ugly
        end
    end

    function draw(window, toPixels)
        % draw the trigger areas on the screen for debugging purposes.
        %
        % window - the window identifier
        % toPixels - a function transforming degree coordinates to pixels
        %            (see <a href="matlab:help Calibration/transformToPixels">Calibration/transformToPixels</a>)
        %
        % See also Trigger>draw.
        
        for trig = triggers_ %ideal, middle
        %for draw = draw_ %ugly
            %trig{i}.draw(window, toPixels); %ideal
            trig.draw(window, toPixels); %middle
            %draw(window, toPixels); %ugly
        end
    end

    function i = initializer(varargin)
        %at the beginning of a trial, the initializer will be called. It will
        %do things like start the eyeLink recording.
        %
        %See also require.
        
        i = currynamedargs(@doInit, varargin{:}); 
    end

    function [release, details] = doInit(details)
        
        transform_ = transformToDegrees(details.cal);
        online_ = 1;
        release = @stop;
        
        function stop
            online_ = 0;
        end
    end

    function [x, y, t] = sample()
        %Implementors should obtian an [x, y, t] sample of the input
        %device. x and y can be NaN if no coordinates are available (e.g. during
        %blinks). Return immediately without waiting around for input.
    end
end
