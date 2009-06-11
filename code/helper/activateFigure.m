function activateFigure(H)
    %if a figure window already exists and is visible, activate it for
    %plotting commands WITHOUT raising it. Otherwise behave as 'figure.'
    if ismember(H, get(0, 'Children'))
        set(0, 'CurrentFigure', H);
        if isequal(get(H, 'Visible'), 'off')
            set(H, 'Visible', 'on');
        end
    else
        figure(H);
    end
end