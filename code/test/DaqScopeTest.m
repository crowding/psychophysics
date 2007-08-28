function serial = DaqScopeTest(varargin)
%      lowChannel: 0
%     highChannel: 0
%           count: 500
%               f: 100
%       immediate: 0
%         trigger: 0
%           print: 0
%         channel: []
%           range: []

% for i=channel
%     DaqAIn(daq(1),i,3);% set gain range
% end
% start=GetSecs;
% params=DaqAInScanBegin(daq(1),options);
% for i=1:length(time)
%     WaitSecs(time(i)+start-GetSecs);
%     err=DaqAOut(daq(1),0,sineWave(i));
%     err=DaqAOut(daq(1),1,squareWave(i));
%     if err.n
%         break;
%     end
%     tOut(i)=GetSecs-start;
% end
% params=DaqAInScanContinue(daq(1),options);
% [data,params]=DaqAInScanEnd(daq(1),options);
%
%         , 'options.channel', [0 1] ...
%         , 'options.range', [0 0] ...
%         , 'options.sendChannelRange', 1 ...

    defaults = namedargs ...
        ( 'device', DaqDeviceIndex() ...
        , 'duration', 3 ...
        , 'options.count', Inf ...
        , 'options.channel', [0 1] ...
        , 'options.range', [2 2] ...
        , 'options.f', 200 ...
        , 'options.immediate', 1 ...
        , 'options.trigger', 0 ...
        , 'options.secs', 0.002 ...
        , 'options.retrigger', 0 ...
        , 'options.sendChannelRange', 1 ...
        , 'options.print', 0 ...
        , 'options.sample', 0 ...
        );
    
    params = namedargs(defaults, varargin{:});

    start = GetSecs();
    params.options.begin = 1;
    params.options.continue = 0;
    params.options.end = 0;
    params.options.sample = 0;
    [data, daqParams] = DaqAInScan(params.device, params.options);
    i = 0;
    params.options.begin = 0;
    params.options.continue = 0;
    params.options.end = 0;
    params.options.sendChannelRange = 0;
    params.options.sample = 1;
    samples = 0;
    serial = {};
    while (GetSecs < start + params.duration+0.02)
        [data, daqParams, s] = DaqAInScan(params.device, params.options);
        i = i + 1;
        samples = samples + numel(data);
        if numel(data) > 0
            serial = {serial s};
%            t = (1:size(data,1))/daqParams.fActual;
%            plot(t, data(:,1));
%            ylim([-5 5]);
%            drawnow;
        end
    end
    stop = GetSecs;
    i / (GetSecs - start);
    printf('Got %d samples ( %f/sec )', samples, samples/(stop - start));
    params.options.begin = 0;
    params.options.continue = 0;
    params.options.end = 1;
    params.options.sample = 0;
    [data, daqParams] = DaqAInScan(params.device, params.options);
    list = [];
    while ~isempty(serial)
        list = [serial{2} list];
        serial = serial{1};
    end
    serial = list;
    if (any(diff(list)) > 1)
        disp('Some packets dropped :(');
    elseif any(diff(list) < 1)
        disp('Some repeated serial numbers :(');
    else
        disp ('All OK received');
    end
end