function this = subsasgn(this, subs, value, varargin)
switch class(this)
    case 'Object'
        %{
        if numel(varargin) > 1
        error('Object:multipleAssign', 'Object does not support parallel assign?');
        end
        %}
        switch subs(1).type
            case '.'
                propname = subs(1).subs;
                if numel(subs) > 1
                    oldval = get(this.wrapped.(propname));

                    %MATLAB's dispatch rules are absolutely bonkers and will
                    %dispatch according to which argument has the highest 'precedence.'
                    %But many overloaded methods (for instance, subsasgn) only make
                    %sense when dispatched on the first argument. So if value is an
                    %Object while oldval is not, this will recurse onto itself and
                    %fail utterly. What to do?
                    %call our own dispatch function, since callign subsref directly is
                    newval = dosubsasgn(oldval, subs(2:end), value);

                    set(this.wrapped.(propname), newval);
                else
                    set(this.wrapped.(propname), value);
                end

            case '()'
                %We're assigning into an array of ourself?
                ref = subs(1).subs;
                switch numel(subs)
                    case 1
                        this(ref{:}) = value;
                    otherwise
                        this(ref{:}) = dosubsasgn(this(ref{:}), subs(2:end), value);
                end
            otherwise
                error('MATLAB:cellAssToNonCell', ...
                    'Cell contents assignment to a non-cell array object.');
        end
    otherwise
        %surprise! You've just been bitten by MATLAB's completely insane
        %dispatch rules! The value you're trying to assign is an Object and
        %has higher 'precedence' than the container you're trying to assign
        %it into.
        %
        %Hah. When you write a subscripted expression, such as a(x) = b,
        %MATLAB will look up the type of a and see if it defines subsasgn,
        %then call subsasgn(a, substruct('()', {x}), b) using a's
        %definition of subsasgn. In other words it dispatches on the first
        %argument of subsasgn. But this is not the same result you get when
        %you invoke subsref(a, ..., b) yourself. Instead, matlab looks at
        %the 'precedence,' ans could invoke a method on A or a method on B
        %depending on how it feels.
        %
        %this leads to the consequence:
        %
        %if A is superior to B, then A has to know how to store itself in B
        %(without the benefit of access to any of b's members.) A has to
        %know how to do this for EVERY TYPE of object inferior to it.
        %
        %Whereas if matlab dispatched on the first argument, then A would
        %just have to know how to store things in itself, and B would also
        %just know how to store things in itself. Like a reasonable object
        %oriented, orthogonal design, which the MathWorks has apparently
        %never even dreamed of.
        %
        %Given that matlab generally dispatches its internal invocations of
        %subsref() on the type of the first argument, you would think that
        %I wouldn't wind up here, since I don't directly call subsref()
        %anywhere. But in fact MATLAB dispatches here when assigning to a
        %new array, e.g.
        %
        %B(index) = Object(...)
        %
        %when B is not yet defined. repmat does this, among other
        %functions.

        ref = subs(1).subs;
        this = dosubsasgn(this, subs, value);

end
end

function target = dosubsasgn(target, subs, value)
%try to invoke matlab's leftmost-argument-dispatch of subsasgn, by brute
%syntactic force...

if(isa(target, 'Object'))
    %normal dispatch is fine here
    target = subsasgn(target, subs, value);
    return
end

ref = subs(1).subs;
switch numel(subs)
    case 1
        switch subs(1).type
            case '.'
                [target.(ref)] = value;
            case '()'
                %If an object is assigned to an index of an empty array, e.g.
                %
                %B(index) = Object();
                %
                %which is done all over the place, including in repmat.m,
                %then matlab (due to broken dispatch rules) winds up calling
                %Object's subsref, which calls here. But even worse, it
                %instantiates a double for the 'target' argument. Since we
                %can't assign ourself into a double, repmat fails. So we have
                %to fix it:
                if isempty(target) && isa(target, 'double')
                    %Note, the information provided to subsref really can't
                    %tell the difference between an assignment into an empty
                    %double array and assignment into a previously-nonexistent
                    %array, despite the fact that it does make a difference to
                    %matlab's ordinary behavior:

                    %>> a(4) = struct();
                    %a =
                    %1x4 struct array with no fields.
                    %>> b = [];
                    %>> b(4) = struct();
                    %??? The following error occurred converting from struct to double:
                    %Error using ==> double
                    %Conversion to double from struct is not possible.
                    %
                    %So consistently handling this case is impossible, and I
                    %have to pick one or the other (I choose the behavior that
                    %makes repmat work...)

                    newtarget = emptyOf(value);
                    %careful, now you have to worry about all the different
                    %sizes of empty arrays 0-by-0, N-by-0, 0-by-0-by-M, etc,
                    %since it affects matlab's 'array growing' rules...
                    target = reshape(newtarget, size(target));
                end

                %now, the array-auto-growing function will go and (surprise!) call
                %Object's constructor with no arguments to fill in the rest of
                %the array's spots. Then repmat will go and do an isequal()
                %check on your Object against the other objects. So make sure
                %you have a constructor which accepts 0 arguments, and that
                %isequal() works on your object...
                target(ref{:}) = value;

            case '{}'
                %And finally, for operations such as
                %object.a{[2,3]} = deal(val2, val3)?
                %
                %MATLAB only captures one output argument from deal() for us.
                %This is because matlab's multiple-ouput=argument mechanism is
                %fundamentally broken.
                %
                %So these kinds of assignments are not possible to emulate.
                if any(cellfun('prodofsize', ref) ~= 1)
                    error('Object:parallelSubsasgn', ...
                        'Parallel assignment in Objects not supported.');
                else
                    [target{ref{:}}] = value;
                end
        end
    otherwise %chained assignment
        switch subs(1).type
            case '.'
                target.(ref) = subsasgn(target.(ref), subs(2:end), value);
            case '()'
                %??? I have no idea how to do auto-growing arrays in this case.
                %Can't support it.
                newtarget = subsasgn(target(ref{:}), subs(2:end), value)
                target(ref{:}) = subsasgn(target(ref{:}), subs(2:end), value);
            case '{}'
                if all(cellfun('prodofsize', ref) == 1)
                    [target{ref{:}}] = subsasgn(target{ref{:}}, subs(2:end), value);
                else
                    error('MATLAB:scalarCellIndexRequired',...
                        'Scalar cell array indices required in this assignment.');
                end
        end
end

end