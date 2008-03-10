% create_img(imgname,fname) loads a specified graphic file using
% imread. The resulting image is saved as a matrix named img to the files
% specified by the file fname in the working directory of virtual machine 0.
% example: 
% create_img('picture.gif','infiles.txt')

function [] = create_img(imgname,fname)
  
  old_wd = pwd;
  
  img = imread(imgname);
  img = rgb2ind(img,gray);

  names = textread(fname,'%s','commentstyle','matlab','delimiter','\n')

  cd(vmget(0,'wd')) % go to the work directory of the virtual machine 0.

  for name = names'
    save(name{:},'img');
  end

  cd(old_wd)