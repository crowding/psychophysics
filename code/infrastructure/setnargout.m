function fout = nsetnargout(nout, fin)
%function fout = nsetnargout(nout, fin)
%A horrid piece of crap.
%
%You see, in any reasonable programming language, if you want to get
%multiple outputs from a function, you return a LIST. There is nothing you
%can not do with returning a LIST that you can do with explicit support for
%multiple output arguments. And, as it turns out, there are things you can
%NOT do with matlab's multiple output arguments that are trivial if every
%function just would return a list instead.
%
%Such as, ACTUALLY GET THE DATA out of a call to a function handle.
%
%a = @(varargin)deal({3, 2, 0});
%
%Suppose you passed 'a' to a helper function. How would that helper
%function call 'a', and have any hope of getting three arguments out? It
%can't. Simply impossible in MATLAB.
%
%Now, TMW thought it would be a good idea to have code have an output as
%well as diagnostic or supplementary information. They chose to use
%
%And let's not get into the incredibly brain-dead dicision of the MathWorks
%to have MATLAB functions change behavior based on not only the number of
%input arguments, but the number of output arguments as well! So if A were
%any particular function even when you know how to call it, there is simply
%NO WAY to figure out how to get rid of it.
%
%Half the functions in the matlab library change behavior when given
%different numbers of inputs. What the hell? Who the hell thought it would
%be a good idea to have the return value of a function be based on its
%output?
%
%There are some potentially good uses for varargout, of course. For
%instance,
%
%[a, b, c] = x(x, y, z)
%I wanted to do somethign to three things, and get three results back. It's
%nice that I can extend this concept to arbitrary numbers of arguments.
%Just one catch, though.
%
%a(x, y, z);
%
%Anyway. Closures save the day on this one. Sort of.
    %
    switch nout
        case 0
            fout = @out0;
        case 1
            fout = @out1;
        case 2
            fout = @out2;
        case 3
            fout = @out3;
        case 4
            fout = @out4;
        case 5
            fout = @out5;
        case 6
            fout = @out6;
        case 7
            fout = @out7;
        case 8
            fout = @out8;
        case 9
            fout = @out9;
        case 10
            fout = @out10;
            %I've stopped at 10. Actually, if you take more than 3 arguments
            %in a function you probably grew up on Fortran, and there's no hope
            %for you.
        otherwise
            error('setnargout:illegalArgument', ...
                'Please don''t abuse varargout this much.');
    end

    function out0(varargin)
       fin(varargin{:}); 
    end

    function [o1] = out1(varargin)
       [o1] = fin(varargin{:}); 
    end

    function [o1, o2] = out2(varargin)
       [o1, o2] = fin(varargin{:}); 
    end

    function [o1, o2, o3] = out3(varargin)
       [o1, o2, o3] = fin(varargin{:}); 
    end

    function [o1, o2, o3, o4] = out4(varargin)
       [o1, o2, o3, o4] = fin(varargin{:}); 
    end

    function [o1, o2, o3, o4, o5] = out5(varargin)
       [o1, o2, o3, o4, o5] = fin(varargin{:}); 
    end

    function [o1, o2, o3, o4, o5, o6] = out6(varargin)
       [o1, o2, o3, o4, o5, o6] = fin(varargin{:}); 
    end

    function [o1, o2, o3, o4, o5, o6, o7] = out7(varargin)
       [o1, o2, o3, o4, o5, o6, o7] = fin(varargin{:}); 
    end

    function [o1, o2, o3, o4, o5, o6, o7,o8] = out8(varargin)
       [o1, o2, o3, o4, o5, o6, o7, o8] = fin(varargin{:}); 
    end

    function [o1, o2, o3, o4, o5, o6, o7, o8, o9] = out9(varargin)
       [o1, o2, o3, o4, o5, o6, o7, o8, o9] = fin(varargin{:}); 
    end

    function [o1, o2, o3, o4, o5, o6, o7, o8, o9, o10] = out10(varargin)
       [o1, o2, o3, o4, o5, o6, o7, o8, o9, o10] = fin(varargin{:}); 
    end
end