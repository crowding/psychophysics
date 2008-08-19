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

    width_ = [];
    wavelength_ = [];
    duration_ = [];
    wavelength_ = [];
    velocity_ = [];
    order_ = [];
    phase_ = 0; %not actually exposed by the Patch but a necessary parameter.
    
    visible = 0; % a misnomer: setting visible means "start playing"
    drawn = 1; %by default, is drawn.
    
    onset_ = 0; %the onset of the current motion process (private)
    queue_ = zeros(0, 13); % the matrix of things currently being drawn...
    
    function [release, params, next] = init(params)
        %capture the patch parameters (as a spritePlayer would render...)
        
        wavelength_ = patch.size(1);
        width_ = patch.size(2);
        duration_ = patch.size(3);
        velocity_ = patch.velocity;
        order_ = patch.order;
        phase_ = 0;
        
        process.reset();
        
        %initialize the delegate drawer.
        next = cd_.init;
        release = @noop;
        queue_ = zeros(0, 13);
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
        color = queue_(:,5:7) .* (exp(-((queue_(:,3)+onset_-next)./queue_(:,10)*2).^2) * [1 1 1]);
        drawn = max(color, [], 2) > accuracy; %whcih we will bother to draw...
        color = color(drawn,:)';
        
        xy = queue_(drawn,[1 2])';
        angle = queue_(drawn,[4])';
        wavelength = queue_(drawn,[8])';
        width = queue_(drawn,[9])';
        phase = queue_(drawn,[12])' - 2*pi*queue_(drawn, [11])'./wavelength * (next-onset_);
        order = queue_(drawn,[13])';
        
        %prune the queue
        queue_(~drawn & (queue_(:,3)+onset_ < next),:) = [];
    end

    function advanceQueue_(next)
        while (isempty(queue_) || all(exp(-(((queue_(:,3)+onset_-next)./queue_(:,10)*2).^2)) > accuracy))
            if nargout(process.next) == 5
                [x, y, t, a, color] = process.next();
                width = width_;
                duration = duration_;
                order = order_;
                phase = phase_;
                velocity = velocity_;
                wavelength = wavelength_;
            else
                [x, y, t, a, color, wavelength, width, duration, velocity, phase, order] = process.next();
            end
            a = a/180*pi;
            queue_ = [queue_; x, y, t, a, color(:)', wavelength, width, duration, velocity, phase, order]; %growing in a loop; bad form
            %                 1  2  3  4  5 6 7      8           9      10        11        12     13 -

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
            stimOnset_ = onset_;
            advanceQueue_(next);
        else
            %reset to show at the next appearance.
            process.reset();
        end
        
        cd_.setVisible(v);
    end
end