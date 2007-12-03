function this = ComboProcess(varargin)
    %function this = ComboProcess(process1, process2)

    process1 = struct('next', @()deal(0));
    process2 = struct('next', @()deal(0));
    process1_ = @()deal(0);
    process2_ = @()deal(0);

    [x1_ y1_ t1_ a1_ c1_] = deal(NaN);
    [x2_ y2_ t2_ a2_ c2_] = deal(NaN);

    varargin = assignments(varargin, 'process1', 'process2');
    this = autoobject(varargin{:});

    setProcess1(process1);
    setProcess2(process2);
    
    function setProcess1(p)
        process1 = p;
        process1_ = p.next;
        [x1_ y1_ t1_ a1_ c1_] = process1_();
    end

    function setProcess2(p)
        process2 = p;
        process2_ = p.next;
        [x2_ y2_ t2_ a2_ c2_] = process2_();
    end

    function [x, y, t, a, c] = next()
        if (t1_ > t2_)
            x = x2_; y = y2_; t = t2_; a = a2_; c = c2_;
            [x2_ y2_ t2_ a2_ c2_] = process2_();
        else
            x = x1_; y = y1_; t = t1_; a = a1_; c = c1_;
            [x1_ y1_ t1_ a1_ c1_] = process1_();
        end
        %{x, y, t, a, c}
        if numel(c) > 3
            disp huh
        end
    end

    function reset()
        process1.reset();
        setProcess1(process1);
        process2.reset();
        setProcess2(process2);
    end
end