function visit(obj, doAssign, applyFun)
    %A visitor pattern for reconstructing objects out of primitive elements
    %and filter function calls.

    if nargin < 3
        applyFun = @noop;
    end
    
    if nargin < 2
        doAssign = @noop;
    end

    dumpit(struct('type', {}, 'subs', {}), obj, doAssign, applyFun);

end

function dumpstruct(subs, obj, doAssign, applyFun)
    for f = fieldnames(obj)'
        dumpit([subs struct('type', '.', 'subs', f{:})], obj.(f{:}), doAssign, applyFun);
    end
end

function dumpobject(subs, obj, doAssign, applyFun)
    props = obj.property__();
    for p = props(:)'
        ns = [subs struct('type', '.', 'subs', p{:})];
        prop = obj.(getterName(p{:}))();
        dumpit(ns, prop, doAssign, applyFun);
    end
end

function dumparray(subs, obj, type, doAssign, applyFun)
    %we have to check in cells, for each sub-object.
    nd = ndims(obj);

    if numel(obj) > 0
        for i = numel(obj):-1:1
            [sub{1:nd}] = ind2sub(size(obj), i);
            substr = substruct(type, sub);
            dumpit([subs substr], builtin('subsref', obj, substr), doAssign, applyFun);
        end
    else
        doAssign(subs, obj, doAssign, applyFun);
    end
end

function dumpit(subs, obj, doAssign, applyFun)
    if isnumeric(obj) || ischar(obj) || islogical(obj) || isempty(obj)
        doAssign(subs, obj);
        return;
    end

    if numel(obj) > 1 || iscell(obj)
        %it's not char and not numeric and not logical, this
        %means it's complicated and we should dump individual
        %entries.
        dumparray(subs, obj, doAssign, applyFun);
        return;
    end

    switch class(obj)
        case 'struct'
            if isfield(obj, 'property__')
                dumpobject(subs, obj, doAssign, applyFun);
                %TODO: filter...
            else
                dumpstruct(subs, obj, doAssign, applyFun);
            end
        otherwise
            if isa(obj, 'Object')
                v = version__(obj);
                dumpobject(subs, obj, doAssign, applyFun);
                %TODO filter...
                dumpstruct([prefix '.version__'], v, printer, doAssign, applyFun);
                applyFun(subs, v.function);
                applyFun(subs, @Object);
            elseif isa(obj, 'PropertyObject')
                dumpstruct(subs, obj, doAssign, applyFun);
                applyFun(subs, str2func(class(obj)));
            elseif isa(obj, 'Object')
                dumpstruct(subs, obj, doAssign, applyFun);
                applyFun(subs, str2func(class(obj)));
            else
                warning('tostruct:badDataType','can''t dump class %s', class(obj));
            end
    end
end