% This examples shows how an integration can be divided into several
% partial integrations and executed in parallel. First, there is the
% parallel code, then follows the sequential code for doing the same
% thing. Last, there is a sequential version of the partial calculation.

% This example works only for Matlab 6 because of the Matlab "quadl" function.

echo on

% integrate on intervall a-b

a = 0;
b = 12;
numseg = 10;
d = (b-a)/numseg; % step size

tic,
% define dispatch function
w = pmjob;
w.expr = 'x=quadl(''sin(x.^3)'',a,b);';
w.argin = {'a','b'};
w.argout = {'x'};
w.datain = {'USERDATA(1)' 'USERDATA(2)'};
w.dataout= {'SETBLOC(1)'};

% The function inputs/outputs could also be defined using:
% w = addspecinput(w,'a','USERDATA');
% w = addspecinput(w,'b','USERDATA');
% w = addoutput(w,'x','SETBLOC');

% define the partial calculations - the blocks of the pmjob
w.blocks = pmblock('dst',createinds(ones(numseg,1),[1 1]));
c = b;
for n=1:numseg,
  w.blocks(n).userdata = {(c-d) c};
  c = c - d;
  echo off
end
echo on

% dispatch the calculations in the network:
err=dispatch(w)
integral = sum(w.output{1})
toc

% do it sequentially:
tic
q = quadl('sin(x.^3)',a,b)
toc

tic,
q2 = 0;
c = b;
for n=1:numseg,
  q2 = q2 + quadl('sin(x.^3)',c-d, c);
  c = c - d;
end
q2
toc

