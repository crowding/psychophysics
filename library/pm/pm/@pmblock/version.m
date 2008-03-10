%VERSION Displays the version number of the PMBLOCK
function v = version(b)

v = double(b(1).v);
v = sprintf('%1.2f', (1+v/100));

