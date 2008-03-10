echo on
% file to test adding and deletion of input and output arguments to a
% pmfun. You could also play around with funed and add and delete
% arguments to see how it works!
% A series of adds and deletes of arguments will be shown. At each
% modification the pmfun object and its pmfun.blocks' first entry is
% shown to demonstrate the structure of the objects.

%three sets of inds:
inds1 = createinds(zeros(20,10),[10 5]) 
inds2 = createinds(cell(4,1),[1 1])
inds3 = createinds(zeros(2,16),[2 4])
%pause

% two sets of filenames
fnames1 = {'file1.mat' 'file2.mat' 'file3.mat' 'file4.mat'}'
fnames2 = {'im1.mat' 'im2.mat' 'im3.mat' 'im4.mat'}'
%pause

% EMPTY
f = pmfun;
f.blocks = pmblock(4)
f.blocks(1) % display first block 
%pause

% ADD SPECIFIC INPUT
f = addspecinput(f,'a1','MARGIN')
f.blocks(1) % display first block
pause

f = addspecinput(f,'a','GETBLOC');
f.blocks = setattr(f.blocks,'src',1,inds1)
f.blocks(1) % display first block
pause

f = addspecinput(f,'a2','TIMEOUT')
f.blocks(1) % display first block
pause

f = addspecinput(f,'b','GETBLOC');
f.blocks = setattr(f.blocks,'src',2,inds2)
f.blocks(1) % display first block
pause

% we also want to send the indices to the slave - for debugging.
f = addspecinput(f,'c','SRC',2)
f.blocks(1) % display first block
pause

f = addspecinput(f,'d','SRC');
f.blocks = setattr(f.blocks,'src',3,inds3)
f.blocks(1) % display first block
pause

f = addspecinput(f,'e','GETBLOC',3)
%f.blocks = setattr(f.blocks,'src',3,inds3)
f.blocks(1) % display first block
pause

f = delspecinput(f,'a')
f.blocks(1) % display first block
pause

f = delspecinput(f,'d')
f.blocks(1) % display first block
pause

f = delspecinput(f,'e')
f.blocks(1) % display first block
pause

f = delspecinput(f,'a1')
f.blocks(1)
pause

f = addspecinput(f,'e','LOADFILE');
f.blocks = setattr(f.blocks,'srcfile',1,fnames1)
f.blocks(1) % display first block
pause

f = addspecinput(f,'f','SRCFILE');
f.blocks = setattr(f.blocks,'srcfile',2,fnames2)
f.blocks(1) % display first block
pause

f = addspecinput(f,'g','LOADFILE');
f.blocks = setattr(f.blocks,'srcfile',3,fnames1)
f.blocks(1) % display first block
pause

f = delspecinput(f,'e')
f.blocks(1)
pause

f = delspecinput(f,'f')
f.blocks(1)
pause


f = addoutput(f,'h','SAVEFILE');
f.blocks = setattr(f.blocks,'dstfile',1,fnames1)
f.blocks(1) % display first block
pause

f = addspecinput(f,'i','DSTFILE');
f.blocks = setattr(f.blocks,'dstfile',2,fnames2)
f.blocks(1) % display first block
pause

f = addspecinput(f,'j','DSTFILE');
f.blocks = setattr(f.blocks,'dstfile',3,fnames2)
f.blocks(1) % display first block
pause

f = addoutput(f,'k','SAVEFILE');
f.blocks = setattr(f.blocks,'dstfile',4,fnames1)
f.blocks(1) % display first block
pause

f = delspecinput(f,'i')
f.blocks(1)
pause

f = deloutput(f,'h')
f.blocks(1)
pause

f = addspecinput(f,'i','DST');
f.blocks = setattr(f.blocks,'dst',1,inds3)
f.blocks(1) % display first block
pause

f = addoutput(f,'j','SETBLOC');
f.blocks = setattr(f.blocks,'dst',1,inds1)
f.blocks(1) % display first block
pause

f = addoutput(f,'l','SETBLOC');
f.blocks = setattr(f.blocks,'dst',2,inds2)
f.blocks(1) % display first block
pause

f = addspecinput(f,'m','DST',1)
f.blocks(1) % display first block
pause

%%
f = deloutput(f,'j')
f.blocks(1)
pause

f = delspecinput(f,'i')
f.blocks(1)
pause

