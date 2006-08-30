%{
* profile the most costly children of update() to see where I am skipping frames...

* something something drift correction? coloring the fixation point blue for now
    *also, adding 'offset' value to insideTrigger

* sophisticated help facility for objects.

* start collecting data on reaction times and see what a good window is...

* triggers should only take effect at the next update, unsure about how to do 
  this. TimeTrigger(t + eps(t)) when this is required, but even that won't work 
  when driven off a time trigger -- time triggers fake their input times.

* make something to unset all triggers when a state transition is reached. 
  Profile the consequences.

* average the eye position over some number of samples after settling?

* doTrial should take some kind of logger argument.

* still unexplained delays in requesting the stimulus time.

* fire-once triggers.

* driver object for experiments. Need to drive the time of each trial.
    * Logging messages. Log initial setup of each trial and all input. Log to 
    * eyelink simpler?

* Properties would be nice to have again...
    * speed unit test?
    * there MUST be some way to make a mutator...

* Test cases that auto-populate their methods
    * use mlint for the scanning step
        * testRunner? see below confusion on xUnit.

*unit test all lines in Object/subsasgn, Object/subsref, PropertyWrapper/subsasgn, PropertyWrapper/subsref.

* Test suites and test runners.
    * what is up with xUnit architecture?
        * a TestCase containe many test methods but the test case does not know
          how to call its own test methods (even if it contains a runTest
          method as part of its interface?). You need a testRunner to do that.
          So what does runTest do for the things you subclass out of testCase?

* inheritance of chained methods
    * somehow need to ask method__ to process a method for inheriting...
        * how to reconcile this with multiple inheritance?
          when a method is wrapped, need to forward the wrapped method to 
          everyone else

        * maybe everyone else gets a chain__ method that usually does nothing 
          but sometimes modifies the method.

        * note: can also do nifty things like log all method calls with this 
          technique -- just wrap every method with a logger...

        * check CLOS's implementation for before-methods, after-methods, and 
          around-methods. CLOS does everything, probably well.
%}
