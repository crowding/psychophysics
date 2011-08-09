function [configurations, counts] = occlusiongen()

    % I need to come up with a set of configurations for a visual stimulus
    % such that there are at least two "target numbers" tested for every
    % "target spacing", and there are at least two "target spacings" tested
    % for every "target count." Additionally I want the list to meet some
    % additional constraints. The actual details are unimportant for this
    % blog.

    % I need to be com up with a list of target spacings and corresponding target
    % counts such that:
    % there are at least two densities
    % the targets on the end do not move further from the terminal flankers
    % than their actual spacings
    % the extent of the stimulus is in some range

    %        ( 'spacing', 2*pi ./([8 9 11 12 14 16 18 20 22 24]) ...
    %9 11 13 16 19 23
    
    min_extent_allowed = 95/180 * pi;
    max_extent_allowed = 165/180 * pi;
    configurations = expandGrid...
        ( 'spacing', 2*pi ./([9 12 15 18 21 25]) ...
        , 'nTargets', 3:8 ...
        , 'stepsize', 0.075 ...
        , 'nsteps', 4 ... %fencepost! this means FIVE appearances, FOUR displacements
        );

    %work it out and determine a minimum and maximum 
    configurations.min_distance = configurations.stepsize;
    configurations.max_distance = configurations.spacing + 2*configurations.stepsize;
    configurations.traversed = (configurations.nsteps).*configurations.stepsize;
    configurations.min_extent = configurations.spacing .* (configurations.nTargets - 1) + configurations.traversed + 2*configurations.min_distance;
    configurations.max_extent = configurations.spacing .* (configurations.nTargets - 1) + 2*configurations.max_distance - configurations.traversed;
    
    configurations.compatible = (configurations.min_extent <= max_extent_allowed) & (configurations.max_extent >= min_extent_allowed) & (configurations.min_extent <= configurations.max_extent);
    %configurations.compatible = (configurations.min_extent <= max_extent_allowed) & (configurations.max_extent >= min_extent_allowed);
    
    %configurations.min_extent = max(configurations.min_extent, min_extent_allowed);
    configurations.max_extent = min(configurations.max_extent, max_extent_allowed);
    
    %now, how many element counts are compatible with each spacing?
    spacingCases = struct...
        ( 'spacing', unique(configurations.spacing)...
        , 'nCases', arrayfun(@(s) sum(configurations.compatible(configurations.spacing==s)), unique(configurations.spacing))...
        , 'nTargets', nan(size(unique(configurations.spacing)))...
        );
    
    %now, how many spacings are available with each element count?
    countCases = struct...
        ( 'spacing', nan(size(unique(configurations.nTargets))) ...
        , 'nCases', arrayfun(@(n)sum(configurations.compatible(configurations.nTargets==n)), unique(configurations.nTargets)) ...
        , 'nTargets', unique(configurations.nTargets) ...
        );
    
    %concatenate the two structures.
    counts = soaCat(1, spacingCases, countCases);
    
    %filter out only those configurations that are compatible
    configurations = soaSubset(configurations, configurations.compatible);
    
    subplot(2,2,1);
    plot(configurations.nTargets, 180/pi * configurations.spacing, 'k.');
    
    xlabel('number of targets');
    ylabel('spacing (degrees)');
    
    %Now I'd like to know how many configurations are compatible with each
    %span of the flankers.
    configurations.extents = cell(size(configurations.compatible));
    %for i = 1:numel(configurations.compatible)
    %    configurations.extents{i} = extents(extents >= configurations.min_extent(i) & extents <= configurations.max_extent(i));
    %end
    %configurations.nExtents = cellfun('prodofsize', configurations.extents);
    subplot(2,2,2);
    plot(configurations.nTargets, configurations.min_extent, 'b.', ...
         configurations.nTargets,configurations.max_extent, 'r.');
    xlabel('number of targets');
    ylabel('extent');
    
    subplot(2,2,3);
    plot(configurations.spacing, configurations.min_extent, 'b.', ...
        configurations.spacing,configurations.max_extent, 'r.')
    xlabel('spacing');
    ylabel('extent');
end

function out = soaCat(along, varargin)
    out = mstructfun(@(varargin)cat(along, varargin{:}), varargin{:});
end

function out = soaSubset(soa, set)
    out = structfun(@(x)x(set), soa, 'UniformOutput', 0);
end

function varargout = mstructfun(f, varargin)
    %How silly of me to think that STRUCTFUN could be used like the above,
    %but "STRUCTFUN only iterates over the fields of one structure." How
    %useless is that?
    fnames = fieldnames(varargin{1});
    [varargout{1:nargout}] = cellfun(@inner, fnames, 'UniformOutput', 0);
    function varargout = inner(fname)
        args = cellfun(@(x)x.(fname), varargin, 'UniformOutput', 0);
        [varargout{1:nargout}] = f(args{:});
    end

    varargout = cellfun(@structify, varargout, 'UniformOutput', 0);
    function out = structify(s)
        stargs = cat(1, fnames(:)', arrayfun(@(x)x,s(:)','UniformOutput', 0));
            out = struct(stargs{:});
    end
end 

function varargout = doCall(fn, c)
    [varargout{1:nargout}] = fn(c{:});
end

function grid = expandGrid(varargin)
    names = varargin(1:2:end);
    args = varargin(2:2:end);
    sizes = cellfun('prodofsize', args);
    indices = fullfact(sizes);
    grid = cellfun...
        ( @(arg, ix)reshape(arg(ix), size(ix)) ...
        , args, num2cell(indices, 1)...
        , 'UniformOutput', 0);
    grid = cell2struct(grid, names, 2);
end

%Our Experiment is as follows.
%Simului are only tested at one eccentricity.
%Stimuli are flanked at either end. 
%The angle spanning the two flankers is between 90 and 135 degrees,
%on either the left or right (or top or bottom?) side of the display.
%In separate blocks, we test on left and right sides of the display.
%The list of available stimuli is such that more than one target spacing is
%tested for each target count, and more than one target count is tested for
%each target.
