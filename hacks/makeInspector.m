function this = makeInspector(container, what, sr, sa)
    %Make an inspector interface for an opject and place it in the given UI container.

    %we are optionally passed a function that performs subsref and subsasgn
    %(curried to the nominal object.)
    if isempty(sr)
        sr = what.property__;
    end
    
    if isempty(sa)
        sa = what.property__;
    end

    %in this given UI panel, make a tree view expansion of an object.
    import javax.swing.*
    import javax.swing.tree.*;
    
    treeview = 
    
    %what does this do?
    rootNode = UITreeNode('root', 'File List', [], 0);
    
    %there is a subscript for each node, and each node gets a string representation of its subscript....
    
    tree = uitree;
    treeModel = DefaultTreeModel('root')
    tree.setModel
end