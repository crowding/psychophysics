function experiments = loadtxtexperiments(glob)
%function experiments = loadtxtexperiments(glob)
    %load experiment data structures from the named files (uses shell globs).
    [s, filenames] = system(sprintf('for i in %s; do echo $i; done', glob));
    filenames = splitstr(sprintf('\n'), filenames);
    filenames(end) = [];
    experiments = cellfun(@loaddata, filenames);
    experiments = [experiments.experiment];
end
