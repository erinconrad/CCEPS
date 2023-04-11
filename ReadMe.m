%% CCEPs code

%{
This code takes data from cortical stimulation sessions and measures
cortico-cortical evoked potentials (CCEPs).

Before running the code, you will need to create a file called cceps_files
somewhere in your path, that will output a structure with the following
elements:
-locations.script_folder (containing the path to the folder containing the
CCEPs code)
-locations.data_folder (containing the path to the folder containing the
pt.mat struct)
-locations.results_folder (containing the path to the folder where we will
output results)
-locations.loginname (containing your ieeg login name)
-locations.pwfile (containing the path to your ieeg password)
-locations.ieeg_folder (containing the path to ieeg codebase)

See the script cceps_files_example.m for an example of how to structure
this file.

Then, navigate to the folder do_run/
>> do_all_in_struct(whichPts)

This accepts the input argument whichPts, which should be an array of
indices (within the pt.mat struct) to run the pipeline on.

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
8) It outputs a structure called "out" containing CCEPs waveforms and a
network and saves it to the results folder

Then, to visualize the CCEPs network and example waveforms, navigate to the
visualization folder and modify display_desired_network.m to set the
correct dataName of the patient you wish to visualize.

Then run
>> display_desired_network
You will first need to define the dataName for which file to run.

This will display the CCEPs network, and you can click different pairs of
stimulation-response electrodes to see the CCEPs waveform for that pair.

Contributors:
Erin Conrad
Brittany Scheid
Caren Armstrong
Eli Cornblath
Joshua Larocque
University of PA, 2020

%}