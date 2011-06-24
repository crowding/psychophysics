
function out = shitprof_readout(l, elements)
    out = cell(elements,2);
    for i = elements:-1:1
        out(i,:) = l(1:2);
        l = l{3};
    end
    
    names = unique(out(:,1));
    transition_times = zeros(numel(names));
    transition_counts = zeros(numel(names));
 
    index = containers.Map(names, 1:numel(names));
    
    cellfun(@transition, num2cell(out(1:end-1,:),2), num2cell(out(2:end,:), 2))
    function transition(from, to)
        from_num = index(from{1});
        to_num = index(to{1});
        
        transition_counts(from_num, to_num) = transition_counts(from_num, to_num) + 1;
        transition_times(from_num, to_num) = transition_times(from_num, to_num) ...
            + to{2} - from{2};
    end

    %sort the transitions by count and by time taken...
    %oh god where is as.data.frame.table.....
    [from, to] = indexgrid(transition_times);
    out = arrayfun(@(a,b,c,d) {a{1},b{1},c,d}, names(from), names(to)...
        , transition_counts, transition_times, 'UniformOutput', 0);
    out = cat(1, out{:});
    
    out = out(cell2mat(out(:,3))~=0,:);
    
    %sort rows of out by the third column
    [~,ix] = sort(cell2mat(out(:,4)));
    out = out(flipdim(ix,1),:);
end