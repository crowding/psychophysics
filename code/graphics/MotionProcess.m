function this = MotionProcess(bounds_, dx_, dt_, n_, delay_, tau_, color_)

    %every so often (interval exponentially distributed governed by tau)
    %the motion process generates a moving object within the specified
    %bounds. THe object moves in a random direction, at some speed.

    this = final...
        ( @next ...
        , @getBounds, @setBounds...
        , @getDx, @setDx...
        , @getDt, @setDt...
        , @getN, @setN...
        , @getTau, @setTau ...
        , @getColor, @setColor);

    local_dir_ = 0; %0 left, 1 right
    global_dir_ = 0;
    counter_ = 0;
    x_ = 0;
    y_ = 0;
    t_ = 0;    
        
    generate();
    
    function generate();
        t_ = t_ + dt_ + delay_ - tau_ * log(rand);
        x_ = bounds_(1) + (bounds_(3) - bounds_(1)) * rand();
        y_ = bounds_(2) + (bounds_(4) - bounds_(2)) * rand();
        counter_ = 0;
        global_dir_ = 360*rand;
        local_dir_ = global_dir_ + 180*round(rand);
    end

    function update();
        counter_ = counter_ + 1;
        
        if counter_ >= n_
            generate();
        else
            x_ = x_ - dx_ * cos(global_dir_ * pi / 180);
            y_ = y_ + dx_ * sin(global_dir_ * pi / 180);
            t_ = t_ + dt_;
        end
    end

    function [x, y, t, a, c] = next()
        x = x_;
        y = y_;
        t = t_;
        a = local_dir_;
        c = color_;
        update();
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
end