function this = Genitive()
    %Genitive is just a way to translate a direct subscript access into
    %matlab's subscript data structure (see SUBSREF)
    %
    %Example:
    % 
    %its = Genitive();
    %>> its.foo
    %
    %ans = 
    %    type: '.'
    %    subs: 'foo'
    this = class(struct([]), 'Genitive');
end