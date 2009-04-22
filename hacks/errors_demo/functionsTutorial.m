function functionsTutorial
    % Peter Meilstrup
    % April 1, 2009

    % Nothing will improve your programming quite so much as learning how to
    % work with functions abstractly. After twenty years on the market,
    % MATALB 7 added functions as a first class datatype. This is a major
    % new (*) feature that can help you do more things with less code.
        
    %In this tutorial I illustrate the first class functions through
    %a few examples. The main example is to show how to fit a psychometric
    %function to some example data. I also show how first class functions
    %are useful for plotting curves and for tracking state. Understanding
    %this is necessary for the next tutorial (where I will discuss the 
    
    %"First class" here means that "function" is a type of data, just like
    %"double" or "char," and you can write code that creates and operates
    %on functions as data.
    
    %MATLAB's support for first class functions is incomplete, but very
    %useful. One limitation is that you cannot define functions on the fly
    %at the command line or in scripts, but only in other functions. So
    %unlike MATLAB tutorials written as a script, where you cut and paste
    %code between the script and the command line, you will have to step
    %through this tutorial in MATLAB's debugger.
    
    %To begin, set a breakpoint on the following line, and run
    %functionsTutorial form the command prompt. At appropriate stopping
    %points a 'keyboard' commadn will bring up the debugger, where you can
    %experiment or explore the workspace. Move to the next breakpoint by
    %pressing the continue button in the debugger or typing 'dbcont'.
    disp('ready!');
    keyboard;
    
%%
    %To begin with, we have the goal of fitting a cumulative distribution
    % function to psychometric data. Let's try to use the logistic function
    % as our psychometric function. I'll begin by defining a function to 
    % compute the logistic CDF. I could place this function definition in
    % another file, but you will see that can often be better organization to
    % define short functions in line.
    function p = logisticCDF(x, mu, s)
        p = 1 ./ (1 + exp(-(x - mu) .* s));
    end
    %Here mu is the mean, and s is the inverse of the width parameter (note 1.)
%% 
    %To illustrate this function, let's plot the logistic CDF with mean 12
    %and shape parameter 1:
    figure(1); clf;
    keyboard;
    x = 0:0.1:20; %what x-coordinate to plot over. 0.1 spacing okay?
    p = logisticCDF(x, 12, 1); %evaluate the function on those points
    plot(x, p); %and plot.
    keyboard;
    
%%  
    %Well, let's step back (and digress) a bit. In MATLAB, how do you like
    %to plot functions? Say you want to plot sin(x). A typical way to do it
    %is:
    clf;
    keyboard;
    x = linspace(0,2*pi, 100);
    y = sin(x);
    plot(x, y, 'b-');
    keyboard;
    
    %We had to make up our own x-coordinate, decide what spacing to use, and
    %evaluate the function on those points. You probably do this whenever
    %you make a graph of a function.
    
%% %It turns out that there is a function
    %in matlab's library that will automate these steps, "fplot:"
    
    clf; keyboard;
    fplot(@sin, [0 2*pi]);
    
    %The argument to the fplot function is not data, but another function,
    %denoted by the @ symbol. The @ symbol here means "the function 'sin'",
    %as opposed to "the error produced by calling sin with no arguments,"
    %which is what yould happen if you just wrote "sin". The @ is an
    %ugliness deriving from matlab's previous rule that bare function
    %names are actually calls to the function.
        
    %In addition to saving you space and time in writing the code to plot a
    %function, fplot has some other advantages. Instead of just plotting points
    %that you feed it, fplot can choose for itself what values to plot,
    %because it can call the underlying function. In fact fplot takes
    %advantage of this freedom by sampling the function more frequently
    %where it is changing more rapidly.
    
    %To see this effect, try graphing a rapidly changing function like
    %sin(1/x), first in the traditional method:
    keyboard;
    clf; hold on;
    
    x = linspace(0,pi, 150);
    y = sin(1./x);
    a1 = subplot(2,1,1);
    plot(x, y, 'r-');
    
    %and then using fplot:
    a2 = subplot(2,1,2);
    fplot(@(x)sin(1./x), [0 pi], 'b-');

    hold off;
    
    %Note that fplot has tracked the rapid changes of the function more
    %closely as the function got closer to x = 0. Inspecting the actual
    %lines that were plotted, we can also se that fplot used fewer points,
    %while remaining more accurate:

    keyboard;
    numel(get(get(a1, 'Children'), 'XData')) %how many points used by plot 
    numel(get(get(a2, 'Children'), 'XData')) %how many points used by fplot 
    
    %The process of selecting the points to evaluate and where to take
    %extra samples is nontrivial -- and you certainly would not want to
    %rewrite it every time you want to plot a different function. With the
    %ability to pass functions as arguments, you have a smart plotting
    %routine that works in a wide variety of cases.
    
    %So when you learn to work with functions instead of raw data, your
    %plotting can work better as well as be easier to write.

%%    
    % I told you above how you refer to a function by putting an @ symbol
    % in front of its name. But I snuck a extra bit of syntax in with the
    % last example:  
    %
    % fplot(@(x)sin(1./x), [0 pi], 'b-');
    %
    % Where in the earlier example I plotted sin(x) by just giving '@sin'
    % as the argument to fplot, there is not a builtin function that
    % calculates sin(1/x), so we have to
    % make one. But it's silly to have to create a new function with a new
    % name (in a new file, or in a subfinction way down at the end of the
    % file) for such a tiny one-off.
    %
    % So instead we can create one inline, with this shorthand notation: An
    % @-sign followed by argument names in parentheses, followed by an
    % expression in terms of those arguments. This creates a function, which
    % you can store in a variable, pass as arguments to other functions, or
    % do whatever else you do with values. Some examples:
    clf;
    keyboard;
    
    %You can make functions and put them into variables:
    a = @(x)cos(1/x); 
    b = @(x)cos(tan(x));
    
    %You call the function the same way you would call any function:
    a(1)
    b(pi)
    
    %You give a function to another function as argument:
    hold on;
    fplot(a, [0 pi], 'r-'); %and give them as arguments to other functions...
    fplot(b, [0 pi], 'b-'); %variable b holds a different function
    
    clf; hold on;
    
    %Functions can go in arrays as well, so if you wanted to do the same
    %thing with several different functions; you can loop over them:
    trigfuncs = {@sin, @cos, @tan, @(x)1./tan(x),  @(x)1./cos(x), @(x)1./sin(x)};
    linespecs = {'r-', 'r--', 'g-', 'g--', 'b-', 'b--'};
    for i = 1:6
        fplot(trigfuncs{i}, [-pi pi], linespecs{i}, 200);
    end
    ylim([-5 4]);
    legend('sin', 'cos', 'tan', 'cot', 'sec', 'csc');
    keyboard;
    
    %Matlab documentation calls functions produced using the @()
    %shorthand "anonymous functions," which is a bit of jargon that gives
    %the illusion that something special is happening. Other languages use
    %terms like 'closures' (note 2) and 'lambda functions' to much the same
    %effect. Don't be bamboozled -- they're just functions. Functions are
    %things, like numbers, strings, or arrays, so it makes perfect sense
    %that you can create them, put them in lists, use tham as arguments,
    %store them in variables and so on.
    
 %% 
    % Coming back from the digression on on plotting, we were plotting the
    % logistic CDF. Now we know that we can plot the logistic cumulative
    % distribution like this: 
    clf; keyboard;
    fplot(@(x)logisticCDF(x, 6, 2), [0 20], 'b-');
    % which shows you a logistic CDF with mean 6 and slope parameter 2.
    % Note how an @() was used to fix the second two arguments of a three
    % argument function, producing a one-argument function suitable for
    % plotting.
    
    % We want to fit some data to a function of this form. I've made a data
    % file with some idealized (fake) data, which I'll load here:
    data = [];
    load('data.mat', 'data');
    keyboard;
    %The first column gives the stimulus value, and the second gives a
    %yes/no response for each trial.
    
    %First, let's try to plot the raw data, to show the frequency of
    %response as a function of stimulus value. It's easy enough to
    %determine which stimulus walues were used:

    stimvals = unique(data(:,1));
    
    %But it's a little trickier to compute the response proportion for each
    %stimulus value. One way to do it is loop, pulling each group of trials
    %out into a cell array:     
    groups = cell(size(stimvals));
    for i = 1:numel(stimvals)
        groups{i} = data(data(:,1) == stimvals(i), 2);
    end
    keyboard;
    %This is a simple example, but you probably write things like it all
    %the time -- iterating over an array to compute a function for each
    %value in the array. You have to do a bit of work around preallocating
    %the groups array and inside the loop using the look index to look up
    %the input and store the output.
    %
    %"cellfun" and "arrayfun" are two functions that
    %matlab provides to take care of these details. You just give a
    %function as the first argument, and the data to looop over in
    %following arguments (in this case iterating over the stimulus values:)
    %Use 'cellfun' when iterating over a cell array and 'arrayfun' when
    %iterating over a numeric array (note 2).)
    
    groups = arrayfun(@(x){data(data(:,1) == x, 2)}, stimvals);
    keyboard;
    
    %Admittedly, since the computation we're doing is just a one
    %liner, that doesn't look like much of a save. But note that this saved
    %me from having to work in terms of an index variable "i" and let me just
    %focus on how to map each stimulus value into its corresponding trial
    %group.
    
    %Now that we've grouped the trials, we can compute the response
    %frequency for each group.
    freq = zeros(size(groups));
    for i = 1:numel(groups)
        freq(i) = mean(groups{i});
    end
    keyboard;

    %Or should that have been written a shorter way?
    freq = cellfun(@mean, groups);

    %Eliminating the boilerplate around the loop means there is more
    %meaning per symbol of code and fewer opportunities for bugs.
    
    %OK, now we have the stimulus values and the response frequencies for
    %each, so we can plot the raw psychophysical data we want to fit:
    plot(stimvals, freq, '.k--');
    keyboard;
    % Now we want to try fitting a function to it. We already defined the
    % logistic CDF, above. We want to find the parameters for the logistic
    % CDF that fit the data in a maximum-likelihood sense. So we need to
    % calculate the (negative) log-likelihood of the data given a CDF. Knowing
    % that we can use a function as an argument to profide the CDF,
    % computing the likelihood for yes-no data just involves calling thes
    % CDF:
    function ll = ynLogLikelihood(data, cdf, varargin)
        p = cdf(data(:,1), varargin{:});
        ll = sum(log(p(logical(data(:,2))))) + sum(log(1-p(~logical(data(:,2)))));
    end
    %The business with "varargin" just passes the third and fourth arguments
    %on to the distribution function unmodified.
    
    %Trying it out, we can tell that a PSE of 15 is more likely than a PSE
    %of 0:
    keyboard;
    ynLogLikelihood(data, @logisticCDF, 15, 0.1)
    ynLogLikelihood(data, @logisticCDF, 0, 0.1)
    
    
    % Now, if we twiddle the mean and shape parameters enough, we can find
    % the parameters that maximize the likelihood of the data. That's the
    % maximum likelihood fit of the logistic function.
    
    % You can imagine that there are many argorithms for twiddling
    % parameters to find a minimum of a function. One of them is in the
    % optimization package and is called 'fminsearch.' As you might expect,
    % it takes a function of one (vector) variable as first argument.
    % Where do we get this function? We can build it based on the data and
    % the distribution function.
    
    keyboard;
    minimizer = @(x) -ynLogLikelihood(data, @logisticCDF, x(1), x(2));
    
    %then we find the params (using a starting point)
    [lparams, llikelihood] = fminsearch(minimizer, [0 0])
    
    %Now we call back to fplot() and see how it looks.
    hold on;
    fplot(@(x)logisticCDF(x, lparams(1), lparams(2)), xlim, 'r-');
    keyboard;
    %And there you have a psychometric curve fit.
    
    %There are some great advantages to building up a function fit by
    %linking functions together this way.
    
    %One is that we accomplish the fit in a very small bit of code (once
    %you subtract my monologue.) Another is that there is a clean
    %separation of responsibilities between the functions we use.
    %fminsearch does not care what the functions it minimizes do or mean;
    %ynLogLikelihood is agnostic to the particular distribution we are
    %working with, and the logistic CDF is a pure function that doesn't
    %care about the data. This clean separation of responsibilities makes
    %it easy to change parts of the complication. For example, if we wanted
    %to fit a Gausian error function, all we have to do is write the
    %cumulative distribution function:
    
    function p = normalCDF(x, mu, isigma)
        p = erf((x-mu).*isigma)/2 + 0.5; %(note 1)
    end

    %and it will plug into the rest of the machinery with no problem, so
    %you can try a fit to a normal CDF by just changing one thing:
    keyboard;
    minimizer = @(x) -ynLogLikelihood(data, @normalCDF, x(1), x(2));
    [nparams, nlikelihood] = fminsearch(minimizer, [0 0])
    fplot(@(x)normalCDF(x, nparams(1), nparams(2)), xlim, 'b-');

    
%%
    %Closures

    % As you have seen, functions are like any other value; they can be
    % stored in variables, used as arguments to other functions. They can
    % also be return values of a function; that is to say, you can write
    % functions that construct and return other functions. This can be a
    % very powerful technique. and it will be critical in the next chapter
    % (on error handling and having your program cleam up after itself.)

    clf;
    keyboard;
    % As a toy example, consider generating random numbers. Suppose in a
    % psychophysics experiment we have to draw a random number on every
    % frame refresh (for random dots, etc.) You are probably aware that
    % the output of a random number generator can be reproduced if you keep
    % track of the 'seed' value that the generator started out with.
    
    % So if you save the seed once, you can generate the exact same
    % sequence again.
    seed = rand('twister');
    
    subplot(3, 1, 1);
    for frame = 1:100 %pretend this is the loop where you draw ots on every screen refresh
        dots(frame) = rand;
    end
    
    %show the history of the dots.
    plot(dots, 'b-');
    title('dots sequence 1');
    keyboard;
    
    %You can generate a new sequence:
    subplot(3, 1, 2);
    for frame = 1:100 %pretend this is the loop where you draw ots on every screen refresh
        dots(frame) = rand;
    end
    plot(dots, 'b-');
    title('dots sequence 2');
    keyboard;
    
    %and then later come back and recreate the original sequence:
    rand('twister', seed); %reset to original state
    subplot(3, 1, 3);
    for frame = 1:100 %pretend this is the loop where you draw ots on every screen refresh
        dots(frame) = rand;
    end
    plot(dots, 'b-');
    title('recreated dots');
    keyboard;
    

%%
    % Now let's say you're interested in combining two cues. Say, you'd
    % like to combine the video stimulus with a noisy audio stimulus. So on
    % each frame you generate two random numbers:s
    rand('twister', seed) %reset to original state
    for frame = 1:100 %pretend this is the loop where you draw dots on every screen refresh
        dots(frame) = rand;
        audio(frame) = rand;
    end
    plot(1:100, dots, 'b-', 1:100, audio, 'g-')
    title('dots + sound');
    keyboard;
    
    % Oops! Now the dots sequence is different for this cue-combining trial
    % than it was in the dots-only case. So even though you are generating
    % the dots the same way, the sequence is different, because you're
    % doing something else with rand() meanwhile. When you analyze the
    % motion content of your trials, you'll have to do different things
    % depending on whether it was a motion-only trial or a motion+sound
    % trial; and you can't recreate a sequence that you used in a dots-only
    % trial for use in a dots+sound trial.
    
    % What we really want for this experiment is two rendom number
    % generators that operate independently. We need a way to CREATE random
    % number generating functions. 
    
    %I'll just write this solution and discuss it below.
    
    function f = makeRNG(privateSeed)
        if ~exist('privateSeed', 'var')
            privateSeed = rand('twister');
        end
            
        f = @callRand;
        
        function varargout = callRand(varargin)
            tmp = rand('twister'); %save current global seed,
            rand('twister', privateSeed); %retrieve private saved seed
            [varargout{1:nargout}] = rand(varargin{:});
            privateSeed = rand('twister'); %save seed for next time
            rand('twister', tmp) %restore previous seed for other, less intelligent random number users
        end
    end
    
    % What you can see is that this is a function that returns a function.
    % The key thing to realize is that each time makeRNG is called, a new
    % version of callRand is produced. Each function produced by makeRNG is
    % distinct, because each time you enter the function makeRNG, a
    % distinct place in memory for the the variable 'seed' is allocated.
    % But when makeRNG returns, that memory is not erased, because it is
    % needed by callRand. So each function returned by makeRNG has its own
    % independent variable it calls privateSeed.
    
    % What that means is that you can call makeRNG twice, and it will
    % produce two generator functions, and each function will keep track of
    % its own seed.
    
    % This trick is called in computer science parlance a 'closure',
    % because when you create the function callRand it 'closes over' the
    % variables in its scope. I don't get that name either. It's one of
    % those bits of jargon that you're as well off ignoring because it makes
    % less sense than the thing it refers to.
    
    %To demonstrate that it works, I can recreate the dots sequence from
    %our first trial while also generating the random numbers for audio
    %noise.
    
    % You might want to run the below while setting breakpoints in
    % callRand, to see that a different seeds are kept for the functions
    % stored in dotsRand and audioRand.

    dotsRand = makeRNG(seed); %one random number generator
    audioRand = makeRNG(); % another
    
    for frame = 1:100 %pretend this is the loop where you draw dots +sound on every screen refresh
        dots(frame) = dotsRand();
        audio(frame) = audioRand();
    end
    plot(1:100, audio, 'g-', 1:100, dots, 'b-')
    title('recreated dots + sound');
    
    %So now we can recreate the original dots sequence while generating
    %extra random numbers for audio, and the two streams of random numbers
    %do not interact.
    
    %Understanding how the function produced by makeRNG hangs onto its seed
    %will be useful for the sequel, where I show how to make your programs
    %clean up after themselves. Until then...
    
%%-------------
    
    % (note 1): More commonly the logistic CDF is written as:
    % (1 + exp(-(x - mu) / s)); that is, dividing by s in the exponential
    % instead of multiplying. Similarly the normal CDF is defined in terms
    % of the standard deviaion. However, these don't work well for curve
    % fitting, because plausible values of s exist on both sides of zero
    % (your subject could be responding 'yes' for smaller stimulus
    % values...), but for a curve fitting algorithm to move from positive
    % to negative would have to pass through zero. Using the width
    % parameters non-inverted will lead a function minimizer to become
    % stuck on one side or the other. 
    
    % (note 2) Matlab's anonymous functions (using the @(x)expr syntax) are not
    % actually closures in the computer science sense, but "handles to
    % nested functions," using the @name syntax as in 
    % the random number generator example, are closures. There is no reason
    % for this distinction; "anonymous" and "nested" functions appeared in
    % the same release of MATLAB and *ought* to be just different syntax to
    % create, simply, "functions." It seems that the tendency to confuse different
    % syntax for things with different things themselves in this case
    % provoked Mathworks engineers to forget the actual simplicity at hand
    % and then invent distinctions between three or four types of function
    % (file functions and subfunctions being the others) where there does
    % not need to be more than one. As a user of Matlab, you're compelled
    % to follow these missteps.
    
end