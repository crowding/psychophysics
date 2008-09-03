% A Cauchy sprite player. also a drop-in replacement for the sprite player
% and patch, but works better, to play sprites with arbitrary SCALING and
% SIZE (and inter-frame timing!)

function this = CauchySpritePlayer(varargin)

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
        queue_ = struct('x', {}, 'y', {}, 't', {}, 'angle', {}, 'color', {}, 'width', {}, 'duration', {}, 'wavelength', {}, 'velocity', {}, 'order', {}, 'phase', {});
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
        try
            color = reshape([queue_.color], 3, numel(queue_)) .* ([1;1;1] * reshape(exp(-(([queue_.t]+onset_-next)./[queue_.duration]*2).^2), 1, []));
        catch
            noop()
        end;
        isDrawn = max(color, [], 1) > accuracy; %whcih we will bother to draw...
        color = color(:,isDrawn);
        
        xy = [queue_(isDrawn).x; queue_(isDrawn).y];
        angle = [queue_(isDrawn).angle] / 180 * pi;
        wavelength = [queue_(isDrawn).wavelength]; 
        width = [queue_(isDrawn).width];
        phase = [queue_(isDrawn).phase] - 2*pi*[queue_(isDrawn).velocity]./wavelength * (next-onset_);
        order = [queue_(isDrawn).order];
        
        %prune the queue
        try
            queue_(~isDrawn & reshape([queue_.t]+onset_ < next, 1, []),:) = [];
        catch
            noop();
        end
    end

    function advanceQueue_(next)
        while isempty(queue_) || queue_(end).t + onset_ < next || exp(-(((queue_(end).t+onset_-next)./queue_(end).duration*2).^2)) > accuracy
            n = nargout(process.next);
            if n == 5
                [s_.x, s_.y, s_.t, s_.angle, s_.color] = process.next();
            elseif n == 11
                [s_.x, s_.y, s_.t, s_.angle, s_.color, s_.wavelength, s_.width, s_.duration, s_.velocity, s_.phase, s_.order] = process.next();
            else
                ss_ = process.next();
                if isempty(ss_)
                    return;
                end
                for i = fieldnames(ss_)'
                    s_.(i{1}) = ss_(end).(i{1});
                end
            end
            
            if isempty(s_.x) || isnan(s_.x) %what it does, or did, if there isn't an object to add.
                return;
            end
            
            queue_ = [queue_; s_(:)'];
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
        cd_.setVisible(v && drawn);
    end
end