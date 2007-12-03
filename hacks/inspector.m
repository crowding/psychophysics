function [release, invoke, refresh] = inspector(objec)

    %The object here is to edit an 'object' using the variable inspector. We
    %have to do periodic updates (but that is fine, we can handle it
    %between trials and the java can run undisturbed on the other processor...)

    %we need to copy our shit to the base workspace. Ugh.
    %Try not to clobber, and to clean up afterwards...
    basevars = evalin('base', 'who');

    obj = objec;
    orig = toraw(objec);

    newvars = genvarname({'edit_'}, basevars);
    [editingVar] = deal(newvars{:});

    assignin('base', editingVar, orig);

    release = @() evalin('base', join(' ', {'clear', newvars{:}}));
    invoke = @()openvar(editingVar);
    refresh = @ref;

    function ref()
        %here's where the real work is. Compare the saved info with the changes
        %to the raw and real objects, then apply changes to the original
        %object.

        o = Obj(obj); %wrap so that we can do subsasgn the same way as with structs

        edited = evalin('base', editingVar);
        %test modifications...
        changed = orig;

        changes = cell(0, 2);
        diffvisit(orig, edited, @change, @noop);
        diffvisit(orig, obj, @change, @noop);

        %if we got through that then there's not much wrong with the mods...

        %now apply the changes.
        for i = changes'
            [sub, what] = i{:};
            subsasgn(o, sub, what);
        end

        %and re-assign back to the workspace
        orig = changed;
        assignin('base', editingVar, orig);

        function change(sub, what)
            subsasgn(changed, sub, what);
            changes(end+1, :) = {sub, what};
        end
    end

end


%the 'refresh' option looks for changes

%{
%wrap it up
x = wrapped(w);

%give me a panel in the window

%open a window
f = figure('MenuBar', none);
p = uipanel('Parent', f, 'Clipping', 'on');


%wrapped things behave like structs
if isstruct(x)
    fs = fieldnames(x)

    %create a bunch of labels for the properties
    
    for i = fs(:)'
        labels(i) = uicontrol('Style', 'text', 'String', i{1}, 'Parent', p, 'Position')
    end
    c = 
end

%}