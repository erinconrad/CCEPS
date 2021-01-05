%% CCEPs code

%{
This code takes data from cortical stimulation sessions and measures
cortico-cortical evoked potentials (CCEPs).

To run the code, first open up the script cceps.m and modify the dataName,
the times of the stimulation session (in seconds according to ieeg.org
times) and the path to your ieeg.org password file. Also modify the
stimulation parameters as needed.

Then, navigate to the folder containing cceps.m and run
>> cceps

The code works according to the following pipeline
1) Downloads ieeg data for the stim session
2) Automatically identifies very high amplitude signals in each channel
(candidates for potential stim artifacts)
3) It then narrows these candidate artifacts down to those that occur on an
expected beat (e.g., 1 Hz for 30 times) consistent with the stimulation
parameters. 
4) It then determines which channel the stimulation occurred on based on
the highest amplitude stimulation, and returns the final list of
stimulation artifacts
5) It then performs averaging of the EEG signals during the stimulation
period, time-locked to the stimulus artifact
6) It then automatically identifies the N1 and N2 waveforms of the CCEPs,
with some basic artifact rejection
7) It then builds a CCEPs network based on either N1 or N2 amplitude.

%}