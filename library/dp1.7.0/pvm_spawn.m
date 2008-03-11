function [numt,tid]=pvm_spawn(task,argv,flag,where,ntask)
% [numt,tid]=pvm_spawn(task,argv,flag,where,ntask)

[numt,tid]=m2pvm(300,task,argv,flag,where,ntask);