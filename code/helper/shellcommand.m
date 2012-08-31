function [status, result] = shellcommand(varargin)
%function [status, result] = shellcommand(varargin)
%Run a command with every word escaped and quoted.
args = cellfun(@shellquote, varargin, 'UniformOutput', 0);
[status, result] = system(sprintf('%s ', args{:}));
