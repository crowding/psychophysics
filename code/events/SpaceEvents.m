function this = SpaceEvents()
%base class for event managers that track a @-D spatial input (e.g. mouse,
%eye) over time.

%-----public interface-----
this = public(@add, @remove, @update, @clear, @draw, @initializer, @sample);

%-----private data-----

%The event-oriented idea is based around a list of triggers. The
%lists specify a criterion that is to be met and a function to be
%called when the criterion is met.

%there are alternatives for how to maintain the trigger list. The
%datatype of the list appears to be a source of much overhead when calling
%update. Right now the middle alternative seems fastest, for whatever
%reason.

%triggers_ = cell(0); %ideal
triggers_ = struct('getId', {}, 'check', {}, 'draw', {}, 'setLog', {}); %middle

transform_ = [];
online_ = 0;
log_ = [];

%----- methods -----

