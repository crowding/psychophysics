function p = logitcdf(x, mu, s)
    p = 1 ./ (1 + exp(-(x - mu) ./ s));
end