function [values,periods] = make_fake_continuous_data(data,chLabels,fs)

fnames = fieldnames(data);
nstims = length(fnames);
nchs = length(chLabels);

values = [];

% intialize periods struct
periods = repmat(struct('start_time', [], 'end_time', [], 'start_index', [], 'end_index', [], 'name', []), nchs, 1);


for i = 1:nstims
    fname = fnames{i};
    C = strsplit(fname,'_');
    assert(length(C)==2) % expect two channels

    chlabel1 = C{1};
    chlabel2 = C{2};

    num1 = regexp(chlabel1, '\d+', 'match'); num1 = str2double(num1{1});
    num2 = regexp(chlabel2, '\d+', 'match'); num2 = str2double(num2{1});

    assert(num2 == num1+1); % expect channel 2 is one more than channel 1

    v = data.(fname);

    % Add data to running values
    start_index = size(values,1) + 1;
    end_index = size(values,1) + size(v,1);
    start_time = start_index/fs;
    end_time = end_index/fs;
    values = [values;v]; % literally concatenate the data from the current run with the prior data

    % Add information to my periods structure
    chIndex = strcmp(chlabel1,chLabels); % find the index in chLabels that matches the first channel label;
    periods(chIndex).start_index = start_index;
    periods(chIndex).end_index = end_index;
    periods(chIndex).start_time = start_time;
    periods(chIndex).end_time = end_time;
    periods(chIndex).name = chlabel1;

    
end

end