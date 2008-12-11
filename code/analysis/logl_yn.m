function fn = logl_yn(cdf, data, lambda)
%function logitlogl(data, cdf, lambda)
%
%does not return a value; returns a function which evaluates the negative log
%likelihood of yes/no data according a parameterized CDF.
%
%Retuns a function (e.g. to be used with fminsearch.)
%second output argument of the function also happens to give the derivative
%of the log likelihood
%
%The optional argument lambda introduces a constant probability of subjects
%guessing randomly
%
%the data is of the form [coord; nYes; nNo].

if nargin < 3
    lambda = 0;
end

fn = @logl;

    function [l, hess] = logl(param)
        %the log probability of each observation is equal to:
        args = num2cell(param);
        if (nargout == 2)
            %something about computing the Hessian
        end

        p = cdf(data(:,1), args{:}) .* (1-lambda) + 0.5*lambda;
        
        l = -sum(log(p).*data(:,2) + log(1-p).*data(:,3));

        cla;
        plot(data(:,1), data(:,2) ./ (data(:,1) + data(:,2)), 'k.');
        hold on;
        plot(data(:,1), cdf(data(:,1), args{:}), 'b-');
        drawnow;
        
        %compute the Hessian matrix, if necessary
        if (nargout >= 2)
            error('not written');
        end
    end

end