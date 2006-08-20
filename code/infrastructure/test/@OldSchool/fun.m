function [this, val] = fun(this)
    val = this.val;
    this.val = val + 1;
end