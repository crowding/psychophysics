function this = ComboProcess(process1_, process2_)
    %function this = ComboProcess(process1, process2)

    process1_ = process1_.next;
    process2_ = process2_.next;
    
    [x1_ y1_ t1_ a1_ c1_] = process1_();
    [x2_ y2_ t2_ a2_ c2_] = process2_();
    
    this = final(@next);
    
    function [x, y, t, a, c] = next()
        if (t1_ > t2_)
            x = x2_; y = y2_; t = t2_; a = a2_; c = c2_;
            [x2_ y2_ t2_ a2_ c2_] = process2_();
        else
            x = x1_; y = y1_; t = t1_; a = a1_; c = c1_;
            [x1_ y1_ t1_ a1_ c1_] = process1_();
        end
        %{x, y, t, a, c}
    end
end