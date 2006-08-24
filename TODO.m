%{
* doTrial should take some kind of logger argument.

* still unexplained delays in requesting the stimulus time.

* drift correction (simulate with set-cursor in mouse mode)

* Cancel button. pressing esc in the mainloop for now; may want keyboard event
  driver in the future.

* TIMING. need to reference the playing of a movie off of screen refreshes;
  * screen updates need a 'next refresh' parameter to say precisely when the 
  next frame should be scheduled.
    * make sure I know where the ApparentMotion object places its 0 time, and 
    * record the time diff between its 0 and the frame it starts in.

* Some way to save and load the state of a trial -- closures will re-attach
  themselves to their workspaces when loaded, which is good, but think about
  forwasrds compatibility. Need something like load protection for it.
    * How to trigger off this when loading?
        * need an enclosing matlab-style object?

* enclosing matlab-style object for:
    * straightforward property access
    * operator overloading
    * load-upgrade operations

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
