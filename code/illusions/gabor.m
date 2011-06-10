function accum = gabor(xeval, yeval, varargin)
    %evaluate the sum of some gabor functions. Takes ersatz named arguments
    %like so:
    %
    %"x" and "y" are the centers of the gabor patches
    %"orient" is in radians
    %"lambda" is the center wavelength in frequency
    %"phase" is is radians, evalutated relative to the center of the patch
    %"semimajor" is the size of the envelope
    %(optional) semiminor is also in width of envelope, defaults to 
    %(optional) "envelope_orient" defaults to the same as orient
    
    %slightly horrid: the order of fields in this struct must match the
    %arguments to EACH below
    defaults = struct ...
        ( 'x', 0 ...
        , 'y', 0 ...
        , 'orient', 0 ...
        , 'lambda', 1 ...
        , 'phase', 0 ...
        , 'color', 0.5 ...
        , 'semimajor', 0.5 ...
        , 'semiminor', [] ...
        , 'envelope_orient', [] ...
        );
    
    arguments = namedOptions(defaults, varargin{:});

    if isempty(arguments.semiminor)
        arguments.semiminor = arguments.semimajor;
    end
    arguments.semiminor(isnan(arguments.semiminor)) = arguments.semimajor(isnan(arguments.semiminor));
 
    if isempty(arguments.envelope_orient)
        arguments.envelope_orient = arguments.orient;
    end
    arguments.envelope_orient(isnan(arguments.envelope_orient)) = arguments.orient(isnan(arguments.envelope_orient));
 
    arguments = expand(struct2cell(arguments));
    
    accum = zeros(size(xeval));
 
    %the slightly horrid
    arrayfun(@each, arguments{:});
    
    %in theory we can evaluate a bunch of gabors in parallel using bsxfun and matrix
    %math. But that would blow memory.
    
    %slightly horrid: argument list must match order of field in default
    %struct
    function each(x, y, orient, lambda, phase, color, semimajor, semiminor, envelope_orient)
        out = cos( ((xeval-x)*cos(orient)+(yeval-y)*sin(orient) ) * (2*pi/lambda) + phase) ...
              .* exp( -(((xeval-x)*cos(envelope_orient)+(yeval-y)*sin(envelope_orient)).^2/semimajor.^2) ...
                      -(((xeval-x)*sin(envelope_orient)-(yeval-y)*cos(envelope_orient)).^2/semiminor.^2));
        
                  %deal with possibly colored contrasts.
        accum = bsxfun(@plus, accum, bsxfun(@times, reshape(color, 1, 1, []), out));
    end

    function args = expand(args)
        %force singleton expansion
        for i = 1:numel(args)-1
            args{i+1} = bsxfun(@first, args{i+1}, args{i});
        end
        for i = numel(args)-1:-1:1
            args{i} = bsxfun(@first, args{i}, args{i+1});
        end
    end

    function x = first(x, y)
        x = x + 0*y;
    end
end