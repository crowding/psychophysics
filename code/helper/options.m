function args = options(defaults, varargin)
    %like namedargs, but enforcing that options are limited to the
    %defaults.
    
    args = namedargs(defaults, varargin{:});
    
    notrec = join(', ', setdiff(fieldnames(args), fieldnames(defaults)));
    if ~isempty(notrec)
        error('options:unrecognizedOption', 'option(s) ''%s'' not recognized', join(', ', notrec));
    end
end