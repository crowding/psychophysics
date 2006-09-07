function c = flattenlinkedlist(ll, n)

c = cell(1, n);

while n >= 1
    if iscell(ll{end})
        r = ll(1:end-1);
        [c{n-numel(r)+1 : n}] = deal(r{:});
        n = n - numel(r);
        ll = ll{end};
    else
        [c{1 : n}] = deal(ll{:});
        ll = {};
        break;
    end
end

if ~isempty(ll)
    warning('flattenlinkedlist:itemsleftover', 'Items left over from list flattening!');
    c = cat(2, c, ll);
end