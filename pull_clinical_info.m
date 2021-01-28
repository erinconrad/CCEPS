function clinical = pull_clinical_info(name)

file_name = 'Stim info.xlsx';

% Get sheetnames
sn = sheetnames(file_name);

found_it = 0;

for s = 1:length(sn)
    T = readtable(file_name,'Sheet',s);
    
    % Read ieeg name
    curr_name = T.IeegName{1};
    
    if strcmp(name,curr_name)
        found_it = 1;
        break
    end
end

if found_it == 0
    clinical = [];
    fprintf('\nWarning, no clinical info for %s\n',name);
    return
end

%% Initialize things
clinical.stim_electrodes = {};
clinical.clinical.stim_sz_elecs = {};
clinical.clinical.soz_anatomic = {};
clinical.ad = {};
clinical.sz = {};
clinical.current_test_elecs = {};


%% Add easy stuff
clinical.name = name;
clinical.current = T.Current(1);
clinical.start_time = T.MainStimStartTime(1);
clinical.end_time = T.MainStimEndTime(1);
clinical.other = T.Other(1);
clinical.clinical_effects = T.ClinicalEffects(1);

%% Add stim electrodes
if iscell(T.Electrodes)
    for s = 1:length(T.Electrodes)
        if ~isempty(T.Electrodes{s})
            clinical.stim_electrodes = [clinical.stim_electrodes;T.Electrodes{s}];
        else
            break
        end
    end
end

%% Add clinical stim seizure electrodes
if iscell(T.ClinicalStimSeizureElecs)
    for s = 1:length(T.ClinicalStimSeizureElecs)
        if ~isempty(T.ClinicalStimSeizureElecs{s})
            clinical.clinical.stim_sz_elecs = [clinical.clinical.stim_sz_elecs;T.ClinicalStimSeizureElecs{s}];
        else
            break
        end
    end
end

%% Add anatomic SOZ
if iscell(T.SuspectedSOZAnatomic)
    for s = 1:length(T.SuspectedSOZAnatomic)
        if ~isempty(T.SuspectedSOZAnatomic{s})
            clinical.clinical.soz_anatomic = [clinical.clinical.soz_anatomic;T.SuspectedSOZAnatomic{s}];
        else
            break
        end
    end
end


%% Add Afterdischarges
if iscell(T.Afterdischarges)
    for s = 1:length(T.Afterdischarges)
        if ~isempty(T.Afterdischarges{s})
            clinical.ad = [clinical.ad;T.Afterdischarges{s}];
        else
            break
        end
    end
end

%% Add seizures
if iscell(T.Seizures)
    for s = 1:length(T.Seizures)
        if ~isempty(T.Seizures{s})
            clinical.sz = [clinical.sz;T.Seizures{s}];
        else
            break
        end
    end
end

%% Add current test electrodes
if iscell(T.CurrentTestElectrodes)
    for s = 1:length(T.CurrentTestElectrodes)
        if ~isempty(T.CurrentTestElectrodes{s})
            clinical.current_test_elecs = [clinical.current_test_elecs;T.CurrentTestElectrodes{s}];
        else
            break
        end
    end
end

%% Add electrode map
for m = 1:length(T.Electrode)
    clinical.map(m).electrode = T.Electrode{m};
    clinical.map(m).target = T.AnatomicalTarget{m};
end

end