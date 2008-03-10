path('/home/argon/ersva/imgbeta5/obj_util',path);


%STARTUP for Parallel Matlab Toolbox

if isunix % only supported on UNIX like systems.
  
    path(getenv('PM_PATH'),path)
   
    if ~isempty(getenv('PM_DEFHOSTS')) & isempty(getenv('PMSPAWN_BLOCK'))
      if exist(getenv('PM_DEFHOSTS')) == 2
	disp('Default PVM hostfile found.');
	pvme_default_config(getenv('PM_DEFHOSTS'));  % copy this file to
						     % /tmp/pvmedefconf.userid
      end
    end
    
    % Only in instances started by pmspawn
    if ~isempty(getenv('PMSPAWN_BLOCK'))
      pm_spawnstartup;
      pmextern;
    end

end



