function this = MotionProcess(bounds_, dx_, dt_, n_, tau_)

    %every so often ( interval exponentially distributed governed by tau)
    %the motion process generates a moving object within the specified
    %bounds. It actually embodies two processes, a left and a right.

    this = final...
        ( @getLeft, @getRight...
        , @getBounds, @setBounds...
        , @getDx, @setDx...
        , @getDt, @setDt...
        , @getN, @setN...
        , @getTau, @setTau);

    local_dir_ = 0; %0 left, 1 right
    global_dir_ = 0;
    counter_ = 0;
    x_ = 0;
    y_ = 0;
    t_ = 0;

    left_ = struct('next', @nextLeft);
    right_ = struct('next', @nextRight);
        
    generate();
    
    function generate();
        t_ = t_ - tau_ * log(rand);
        x_ = bounds_(1) + (bounds_(3) - bounds_(1)) * rand();
        y_ = bounds_(2) + (bounds_(4) - bounds_(2)) * rand();
        counter_ = 0;
        local_dir_ = round(rand);
        global_dir_ = round(rand);
    end

    dirindex_ = [-1 1];

    function update();
        counter_ = counter_ + 1;
        
        if counter_ >= n_
            generate();
        else
            x_ = x_ + dx_ * dirindex_(global_dir_ + 1);
            t_ = t_ + dt_;
        end
    end

    function [x, y, t] = nextLeft(s)
        if local_dir_ == 0
            [x, y, t] = deal(x_, y_, t_);
            update();
        else
            [x, y, t] = deal(NaN);
        end
    end
    
    function [x, y, t] = nextRight(s)
        if local_dir_ == 1
            [x, y, t] = deal(x_, y_, t_);
            update();
        else
            [x, y, t] = deal(NaN);
        end
    end

    function left = getLeft();
        left = left_;
    end

    function right = getRight();
        right = right_;
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
end