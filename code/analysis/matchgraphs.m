function matchgraphs(handles)
    %match the ranges of the handles to the outer bounds of the ranges...
    
    [xls, yls] = arrayfun(@(x)deal(get(x, 'XLim'), get(x, 'YLim')), handles, 'UniformOutput', 0);
    xls = cat(1, xls{:});
    yls = cat(1, yls{:});
    
    xl = [min(xls(:,1)), max(xls(:,2))];
    yl = [min(yls(:,1)), max(yls(:,2))];
    
    arrayfun(@(x)set(x, 'XLim', xl), handles);
    arrayfun(@(x)set(x, 'YLim', yl), handles);
end