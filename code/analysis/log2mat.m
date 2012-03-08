function log2mat(infile, outfile)

%if it is a gzip file...
[s__, type__] = system(sprintf('file -b "%s"', infile));
if strfind(type__, 'gzip')
    params = struct('gzipfile', {infile});
    reader = @gunziplines;
else
    params = struct('infile', {infile});
    reader = @readlines;
end

parser = LogfileLoader();

require(params, reader, parser.fromreadline);

data = parser.getData(1);
save(outfile,'data');

end

function [release, params] = readlines(params)
    fid = fopen(params.infile);
    params.readline = @()fgetl(fid);
    release = @r;
    function r()
        fclose(fid);
    end
end