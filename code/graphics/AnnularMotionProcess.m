function this = AnnularMotionProcess(bounds_, dx_, dt_, n_, delay_, tau_, color_)

    %every so often (interval exponentially distributed governed by tau)
    %the motion process generates a moving object within the specified
    %annular bounds. The object moves in a random direction.

    this = final...
        ( @next ...
        , @getBounds, @setBounds...
        , @getDx, @setDx...
        , @getDt, @setDt...
        , @getN, @setN...
        , @getTau, @setTau ...
        , @getColor, @setColor, @reset);

    local_dir1_ = 0; %0 left, 1 right
    global_dir1_ = 0;
    local_dir2_ = 0; %0 left, 1 right
    global_dir2_ = 0;
    counter_ = 0;
    x1_ = 0;
    y1_ = 0;
    x2_ = 0;
    y2_ = 0;
    t_ = 0;
    
    alternate_ = 0;
        
    generate();
    
    function generate()
        t_ = t_ + dt_ + delay_ - tau_ * log(rand);
        
        %if events are uniformly distributed within the annulus, then here
        %is a random radius:
        r1 = sqrt(rand()*(bounds_(4).^2-bounds_(3).^2) + bounds_(3).^2);
        r2 = sqrt(rand()*(bounds_(4).^2-bounds_(3).^2) + bounds_(3).^2);
        w1 = rand*2*pi;
        w2 = rand*2*pi;
        
        x1_ = r1 * cos(w1) + bounds_(1);
        x2_ = r2 * cos(w2) + bounds_(1);
        y1_ = r1 * sin(w1) + bounds_(2);
        y2_ = r2 * sin(w2) + bounds_(2);
        
        global_dir1_ = 360*rand;
        global_dir2_ = 360*rand;
        
        a = round(rand);
        
        local_dir1_ = global_dir1_ + 180*a;
        local_dir2_ = global_dir2_ + 180*~a;

        x1_ = x1_ + dx_ * (n_ - 1) / 2 * cos(global_dir1_ * pi / 180);
        x2_ = x2_ + dx_ * (n_ - 1) / 2 * cos(global_dir2_ * pi / 180);
        y1_ = y1_ - dx_ * (n_ - 1) / 2 * sin(global_dir1_ * pi / 180);
        y2_ = y2_ - dx_ * (n_ - 1) / 2 * sin(global_dir2_ * pi / 180);
        
        counter_ = 0;
    end

    function update()
        counter_ = counter_ + 1;
        
        if counter_ >= n_
            generate();
        else
            x1_ = x1_ - dx_ * cos(global_dir1_ * pi / 180);
            x2_ = x2_ - dx_ * cos(global_dir2_ * pi / 180);
            y1_ = y1_ + dx_ * sin(global_dir1_ * pi / 180);
            y2_ = y2_ + dx_ * sin(global_dir2_ * pi / 180);
            t_ = t_ + dt_;
        end
    end

    function [x, y, t, a, c] = next()
        if alternate_
            x = x2_;
            y = y2_;
            t = t_;
            a = local_dir2_;
            c = color_;
            alternate_ = 0;
        else
            x = x1_;
            y = y1_;
            t = t_;
            a = local_dir1_;
            c = color_;
            alternate_ = 1;
            update();
        end
    end
            
    function dx = getDx()
        dx = dx_;
    end

    function setDx(dx)
        dx_ = dx;
    end

    function dt = getDt()
        dt = dt_;
    end

    function setDt(dt)
        dt_ = dt;
    end

    function n = getN()
        n = n_;
    end

    function setN(n)
        n_ = n;
    end

    function tau = getTau()
        tau = tau_;
    end

    function setTau(tau)
        tau_ = tau;
    end

    function color = getColor();
        color = color_;
    end

    function setColor(color);
        color_ = color;
    end

    function reset();
        
    end
end