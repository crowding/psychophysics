## Matlab psychophysics code
Peter Meilstrup

This repository collects code I used in experiment control and development of visual illusions and demos.

It contains a high-level, event-driven framework for psychophysical and oculomotor experimentation, built above the Psychtoolbox, and various experiments built on top of that.

It is poorly organized because *&lt;reasons&gt;* (it is approximately as well organized as can be expected given the pressures it was developed under.)

It includes an older version of Psychtoolbox, compiled in
32-bit mode, which is not compatible with MATLAB versions newer than
2010b. I haven't tried upgrading the version of PTB (and no longer have a legal MATLAB license to work with) so I don't know how hard that will be.

### Installation

In MATLAB, change the working directory to the root of this repository and type `startup`.

Try running `ConcentricDemo` and try pressing the keys indicated.

`DemoNight` and `VortexDemo` show illusions I presented at VSS in 2010.

See the file `code/demos/AdjustableDemo.m` to see how this responsiveness is implemented.

It probably won't work straight away. Contact me over email or Github for help.

### Roadmap

`code` contains all MATLAB code used to perform my experiments.

* `code/defaults` contains some mechanism to configure system-wide defaults (class variable default values etc.) to suit particular experiment rigs. Getting this library running on a new rig probably means writing a new defaults file.

* `code/experiments` concerns implementation of entire experiments.
    * `JumpyRectangle.m` API demo: when used with an Eyelink draws random rectangles anywhere except where you're looking.
    * `Experiment.m` is an object that can be configured to run various constant-stimuli and adaptive psychophysics routines. Most other files in this directory start by configuring an Experiment object with parameter sets, blocking, staircase handlers and so on. `Experiment.m` also arranges for the logging of whatever goes on in an experiment (for code that parses the log files, see [https://github.com/crowding/logfile-reader].
    * Experiment 1 of my thesis is done in `ConcentricDirectionDiscriminabilityCritDistance.m`, which builds an Experiment object around the trial object implemented in `ConcentricTrial.m`.
    * Experiment 2 is done in  `ConcentricDirectionSegment.m`.
    * `ConcentricOculomotor.m` runs a related experiment that used oculomotor pursuit as the response modality, allowing humans and monkeys to run on the same task.
    * `CalibrateEyes.m` and `EyeCalibration.m` implement an eye tracker calibration routine that runs without operator intervention. I usually placed these at the start of blocks in my experiments.

* `code/events` contains the event-driven sort of framework for constructing psychophysics experiments.
    * `mainloop.m` is the heart of it. It is the main graphics loop, which centralizes the responsibility of being very picky about vblank timing and detecting frame drops. For each drawn frame it swaps buffers, calls handlers to draw graphics objects, calls more handlers to collect input data, and calls other handlers to respond to inpus and  advance the experiment's state. Typically each trial of an experiment constructs a MainLoop object, populates it with input handlers, graphics objects and output handlers, and calls `mainLoop.go()`.
    * `Trigger.m` is a trigger manager used for adding and removing input-conditional triggers, and logging the firing of triggers.Typically an experiment trial adds Trigger as one of its event handlers. For example, I enforce fixation by first adding a `circularwindowEnter` to the trigger object to detect fixation, using the callback from that to start the trial, and then adding a `circularWindowExit` condition to the trigger object.
    * Most other files in `events` are helpers to use with Trigger and MainLoop.
    * For an example, of how event-driven programming builds a psychophysics experiment, see `code/experiments/ConcentricTrial.m`.

* `code/infrastructure` contains some implementation of reference-valued objects for MATLAB (to explain this much of which was written before reference objects were added to MATLAB).
    *  `unittest` contains a rather useful unit testing framework for Matlab. See `TestCase.m` and other test cases implemented in various `test` directories.
    * `require.m` implements a sort of `try...finally` or `unwind-protect` and is essential for experiments that talk to hardware.

* `code/graphics` contains various graphic objects you can attach to the main drawing loop.
    * `CauchyDrawer.m` draws Cauchy wavelets, given a callback that tells it where to draw on each frame.
    * `CauchySpritePlayer` builds on CauchyDrawer using it to draw motion pulses (taht have a time of appearance, Gaussian temporal window and specified temporal frequency. In turn, it takes a "motion process"  to tell it "where" and "when" to place the pulses.
    * `CircularCauchyMotion` is a motion process used with `CauchySpritePlayer` that implements the circularly moving animated Gabor wavelets I used as stimuli in my disseration.

* `code/analysis` contains some data analysis routines but I eventually decided to move analysis of particular experiments to separate repositories (and mostly write it in R instead of Matlab.)
    *`MarkSaccades` is a useful routine for detecting saccades in eye position data.

* `code/old_graphics` contains some code that I used in early days before writing the event-driven framework. Most is dead except for the Calibration data structure which is still used.
    * `@calibration/calibrate.m` is a routine to linearize a gamma curve for gray-background experiments, using a photometer connected to the serial port.

* `code/input` contains input drivers for the event-driven framework:
    * `AudioInput.m` wraps the Psychtoolbox audio recording facilities.
    * `EyelinkInput.m` streams data from Eyelink series eyetrackers, wrapping the EyelinkToolbox libraries.
    * `TrackpadInput` allows you do do some nifty things with non-multitouch trackpads from some old. model of Mac laptop. See `code/demos/TrackpadTheremin` for an application.
    * `LabJackInput.m` integrates the LabJack UE9 as used in my physiology rig (to produce a TTL_reward signal, record analog eye trackign signals and verify VSYNC and frame counts
    * `PowermateInput.m` receives events from the PowerMate knob controller.

* `code/resources` similarly contains event-driven output drivers and hardware interfacing..
    * `AudioOutput.m` contains a driver that manages playing sound samples during experiments.
    * `LabJackUE9.m` is a relatively complete object that controls the LabJack UE9 data acquisition device from Matlab.

* `library` contains an archive of some libraries I used in configuring experimental rigs.
