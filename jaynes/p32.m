%Jaynes 3.2 asks, if we have an urn containing 50 balls, 10 of each color,
%how many draws until there is a 90% chance of getting all colors?

%Consider h(i,j) to be the probability of having seen j colors by the i'th
%draw. The color of the initial ball does not matter; clearly h(1,1) = 1
%and 

h = [1 0 0 0 0]; %initial state

%number of balls in the urn
N = 50;

for j = 2:20
    %Then, having seen i colors in j draws, there are (10i - j) balls in the
    %urn whose colors we have seen, and (50-10i) balls whose colors we have
    %not seen, out of (50-j) balls total
    [iprev, inext] = ndgrid(1:5, 1:5);
    %transition probabilty
    w = (10*iprev - j).*(iprev==inext)+(50 - 10*iprev).*(iprev==(inext-1));
    w = w./(50-j);
    j
    h = h * w
end

%The result is, after 15 draws there is a 92% probability of having
%observed all 5 colors.