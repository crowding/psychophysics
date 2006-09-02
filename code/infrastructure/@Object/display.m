function display(this)
switch numel(this)
    case 1

        if ~isempty(this.constructor__)
            f = functions(this.constructor__);
            disp([f.function ':']);
        end
        
        if isfield(this.orig, 'properties__')
            propnames = this.orig.properties__;
            values = cellfun(@(prop) this.orig.(getterName(prop))(), propnames, 'UniformOutput', 0);
            args = {propnames{:}; values{:}};
            disp(scalarstruct(args{:}));
        end
            
        methods = fieldnames(this.orig);
        save = methods(end);
        csv = strcat(methods, {', '});
        csv(end) = save;

        disp(['Methods: ', csv{:}]);

    otherwise
        disp(sprintf('[%s Object]', ...
            join('x', cellstr(num2str(size(this)', '%g')))));
end
end