function this = GammaDistribution(varargin)
%a gamma distribution object, which maintains a private seed (invoking it will nto affect the global seed. However,
%it will switch the generator into the Mersenne twister, if your other code is
%sloppy enough not to specify the method. (Unavoidable -- there is no way
%to read and save the method currently being used by matlab's RN generator.

offset = 0;
scale = 1;
shape = 1;
rand('twister', sum(100*clock));
randn('state', sum(100*clock));
seed = rand('twister');
seedn = randn('state');
%NOTE! seed is useless for recalling state if the
%save happens after the event. Dump out structures for trials before
%running them.

persistent init__;
this = autoobject(varargin{:});

    function r = e(x)
        c = ev(offset);
        theta = ev(scale);
        k = ev(shape);
        s = rand('twister');
        sn = randn('state');
        try
            rand('twister', seed);
            randn('state', seedn);
            r = c + randg(k) .* theta;
            seed = rand('twister');
            seedn = randn('state');
        catch
            rand('twister', s);
            randn('state', sn);
            rethrow(lasterror);
        end
        rand('twister', s);
        randn('state', sn);
    end
end