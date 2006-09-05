function display(this)
switch numel(this)
    case 1
        disp([this.version.function ':']);
        disp(structfun(@(f)f(), this.getters, 'UniformOutput', 0));
        disp(['Methods: ', join(', ', this.wrapped.method__());]);
    otherwise
        disp(sprintf('[%s Object]', ...
            join('x', cellstr(num2str(size(this)', '%g')))));
end
end