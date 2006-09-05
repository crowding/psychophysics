function varargout = subsref(this, s)

switch s(1).type
    case '.'
        name = s(1).subs;
        switch numel(this)
            case 1
                if isfield(this.getters, name)
                    switch numel(s)
                        case 1
                            [varargout{1:nargout}] = this.getters.(name)();
                        otherwise
                            [varargout{1:nargout}] = subsref(this.getters.(name)(), s(2:end));
                    end
                else
                    switch numel(s)
                        case 1
                            [varargout{1:nargout}] = this.wrapped.(name);
                        otherwise
                            [varargout{1:nargout}] = subsref(this.wrapped.(name), s(2:end));
                    end
                end
            otherwise
                %dot-reference on an object array...
                [wraps{1:nargout}] = this.wrapped;
                switch numel(s)
                    case 1
                        varargout = cellfun(@(f)f.(s(1).subs), ...
                            wraps, 'UniformOutput', 0);
                    otherwise
                        error('MATLAB:extraneousStrucRefBlocks', ...
                            ['Field reference for multiple structure ' ...
                            'elements that is followed by more reference' ...
                            'blocks is an error.']);

                        % OTOH, this actually be more useful than matlab,
                        % by allowing references like obj.a(4) where obj is
                        % an array.
                        %varargout = cellfun(@(f)subsref(f.(s(1).subs), s(2:end)),...
                        %    wraps, 'UniformOutput', 0);
                end
        end

    case '()'
        %trying to access an array of me...
        switch numel(s)
            case 1
                [varargout{1:nargout}] = this(s(1).subs{:});
            otherwise
                [varargout{1:nargout}] = subsref(this(s(1).subs{:}), s(2:end));
        end
    otherwise
        error('MATLAB:cellRefFromNonCell', ...
            'Cell contents reference from a non-cell array object.');
end

end
