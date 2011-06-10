% A Cauchy sprite player. also a drop-in replacement for the sprite player
% and patch, but works better, to play sprites with arbitrary SCALING and
% SIZE (and inter-frame timing!)

function this = CauchySpritePlayer(varargin)

    %to spread the load, only grab this many in a frame, unless you want
    %more...
    queueSize = 128;

    %the 'patch' argument is only used to look up default sizes,
    %velocities, etc. If using a cauchy-sprite process, patch is
    %unnecessary.
    patch = CauchyPatch();
    
    %the 'process' can either be an old-style sprite process (x, y, t, angle, color), or a
    %cauchy-sprite process that describes all the parameters...
    process = [];
    
    log = [];
    
    accuracy = 0.001;
    
    varargin = assignments(varargin, 'patch', 'process', 'log');
    persistent init__;
    this = autoobject(varargin{:});
    
    %here's a nifty way to do selective delegation I just thought of.
    %We have a private CauchyDrawer to provide our draw method...
    cd_ = CauchyDrawer('source', this, 'accuracy', accuracy, 'visible', 0);
    %and we simply expose its draw and update methods.
    this.method__('draw', cd_.draw);
    this.method__('update', cd_.update);

    %to fully specify a cauchy blob we need these fields, and only these
    %fields. this is the queue.

    s_ = struct('x', [], 'y', [], 't', [], 'angle', [], 'color', [], 'width', [], 'duration', [], 'wavelength', [], 'velocity', [], 'order', [], 'phase', []);
    queue_ = struct('x', {}, 'y', {}, 't', {}, 'angle', {}, 'color', {}, 'width', {}, 'duration', {}, 'wavelength', {}, 'velocity', {}, 'order', {}, 'phase', {});
    
    
    visible = 0; % a misnomer: setting visible means "start playing"
    drawn = 1; %by default, is drawn.
    
    onset_ = 0; %the onset of the current motion process (private)
    
    function [release, params, next] = init(params)
        s_ = struct('x', [], 'y', [], 't', [], 'angle', [], 'color', [], 'width', [], 'duration', [], 'wavelength', [], 'velocity', [], 'order', [], 'phase', []);
        
        %capture the patch parameters (as a spritePlayer would render, for
        %backwards compatibiilty)
        s_.wavelength = patch.size(1);
        s_.width = patch.size(2);
        s_.duration = patch.size(3);
        s_.velocity = patch.velocity;
        s_.order = patch.order;
        s_.phase = 0;
        
        process.reset();
        
        %initialize the delegate drawer.
        next = cd_.init;
        release = @noop;
        %queue_ = struct('x', {}, 'y', {}, 't', {}, 'angle', {}, 'color', {}, 'width', {}, 'duration', {}, 'wavelength', {}, 'velocity', {}, 'order', {}, 'phase', {});
        %                 1--------2--------3--------4------------5-6-7--------8------------9---------------10----------------11--------------12-----------13
        queue_ = zeros(13, 0);
    end


    function setAccuracy(s)
        %mirror accuracy setting to the delegate drawer.
        accuracy = s;
        cd_.setAccuracy(s);
    end

    %this is what the delegate drawer needs from us
    function [xy, angle, wavelength, order, width, color, phase] = get(next)
        if ~visible
            return;
        end
        
        %ask for the next item...
        advanceQueue_(next);
        
        %draw the queue...
        color = queue_([5 6 7],:) .* ([1;1;1] * reshape(exp(-((queue_(3,:)+onset_-next)./queue_(9,:)*2).^2), 1, []));
        
        %pick the blobs we will actually bother to draw...
        isDrawn = max(color, [], 1) > accuracy;
        color = color(:,isDrawn);
        
        xy = queue_([1 2],isDrawn);
        angle = queue_(4, isDrawn) / 180 * pi;
        wavelength = queue_(10,isDrawn); 
        width = queue_(8,isDrawn);
        phase = queue_(13,isDrawn) - 2*pi*queue_(11,isDrawn)./wavelength .* (next-onset_-queue_(3,isDrawn));
        order = queue_(12,isDrawn);
        
        %prune the queue
        queue_(:,~isDrawn & queue_(3,:)+onset_ < next) = [];
    end

    function advanceQueue_(next)
        nAdvanced = 0;
        
        while 1
            if ~isempty(queue_)
                %stop filling the queue if any objects presently in the
                %queue are 2x too far ahead to show (disregarding contrast).
                %This is not exactly the right metric, but as close as one
                %can get w/o knowledge of what's coming up.
                ahead = queue_(3,:) + onset_ >= next;
                if any(ahead)
                    ampl = exp(-(((queue_(3,ahead)+onset_-next)./queue_(9,ahead)*2).^2));
                    if min(ampl) < accuracy
                        break;
                    end                    
                end
                %sort of spread out the work....
                %{
                if (nAdvanced >= 3)
                    break;
                end
                if (ampl < accuracy && nAdvanced >= 3)
                   break;
                end
                %}
            end
            n = nargout(process.next);
            if n == 5
                [s_.x, s_.y, s_.t, s_.angle, s_.color] = process.next();
                if isempty(s_.x) || isnan(s_.x) %what it does, or did, if there isn't an object to add.
                    return;
                end
                queue_ = [queue_ [s_.x;s_.y;s_.t;s_.angle;s_.color;s_.width;s_.duration;s_.wavelength;s_.velocity;s_.order;s_.phase]];
                nAdvanced = nAdvanced + 1;
            elseif n == 11
                [s_.x, s_.y, s_.t, s_.angle, s_.color, s_.wavelength, s_.width, s_.duration, s_.velocity, s_.phase, s_.order] = process.next();
                if isempty(s_.x) || isnan(s_.x) %what it does, or did, if there isn't an object to add.
                    return;
                end
                queue_ = [queue_ [s_.x;s_.y;s_.t;s_.angle;s_.color;s_.width;s_.duration;s_.wavelength;s_.velocity;s_.order;s_.phase]];
                nAdvanced = nAdvanced + 1;
            else
                s = process.next();
                if isempty(s)
                    return;
                end

                if isstruct(s)
                    ss_ = s;
                    for i = fieldnames(ss_)'
                        s_.(i{1}) = ss_(end).(i{1});
                    end

                    if isempty(s_.x) || isnan(s_.x) %what it does, or did, if there isn't an object to add.
                        return;
                    end
                    queue_ = [queue_ [s_.x;s_.y;s_.t;s_.angle;s_.color;s_.width;s_.duration;s_.wavelength;s_.velocity;s_.order;s_.phase]];
                    nAdvanced = nAdvanced + 1;
                else
                    if isempty(s) || isnan(s(1))
                        return
                    end
                    queue_ = [queue_ s];
                    nAdvanced = nAdvanced + 1;
                end
            end
            if nAdvanced >= 10
                noop();
            end
        end
    end

    function stimOnset = setVisible(v, next)
        % v:     if true, will start drawing the movie at the next refresh.
        %
        % next:  if exists and set to the scheduled next refresh, gives the
        %        stimulus onset time.
        % ---
        % onset: the stimulus onset time.
        visible = v;
        
        if v
            onset_ = next;
            stimOnset = onset_;
            advanceQueue_(next);
        else
            %reset to show at the next appearance.
            process.reset();
        end
        visible = v;
        cd_.setVisible(v && drawn);
    end

    function setDrawn(d)
        drawn = d;
        cd_.setVisible(d && drawn);
    end

    function setProcess(p)
        process = p;
        process.reset();
    end
end