function [get, set] = accessor(value_)
%creates an accessor.

get = @getter;
%might be even faster if we could avoid these function
%handles being in the same workspace as accessor.
set = @setter;

    function v = getter
        v = value_;
    end

    function v = setter(v)
        value_ = v;
    end
end