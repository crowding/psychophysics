function a = loadobj(a)
% Translate older broken CauchyBars into newer equivalent fixed CauchyBars.

if isstruct(a)
	if ~isfield(a, 'phi')
		%previous versions of CauchyBar rendered the phase argument incorrectly,
		%multiplying it by the temporal frequency "omega". We account for
		%this when translating older objects.
        
        %even older versions of CauchyBar had no phase argument.
        
        %MATLAB lameness #3,834:
        %
        %For fuck's sake! The docs say that loadobj "will be separately
        %invoked for each object". But in practice, I find that this
        %function is invoked with 'a' being either a *single* struct or an
        %entire *array* of structs. I'm willing to accept this behavior
        %if it were actually the case that 'everything is an array' in
        %MATLAB as is so often claimed.
        %
        %But if you've even heard of type theory, you'd know that if a
        %singleton were an array, an operation on a singleton would produce
        %a value whose type is COMPATIBLE with the result of an operation
        %on an array. But this is not true! Struct-subscripting a singleton
        %produces a singleton value, while struct-subscripting an array
        %produces a CELL ARRAY of values.
        a = cell_2_mat(cellmap(@translate, a));
	end
end

function c = translate(c)
    if isfield(c, 'phase')
        sigma = c.order*c.size(1)/2/pi;
        omega = -c.velocity * c.order / sigma;
        c.phi = c.phase * omega;

        c.phi = mod(c.phi, 2*pi);
        if (c.phi > pi)
            c.phi = c.phi - 2*pi;
        end
        c = rmfield(c, 'phase');
    else
        c.phi = 0;
    end
    c = CauchyBar(c);