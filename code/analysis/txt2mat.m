function txt2mat(infile, outfile)
    experiments = loadtxtexperiments(infile);
    save(outfile, 'experiments');
end