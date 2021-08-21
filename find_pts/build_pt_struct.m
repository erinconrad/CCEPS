function build_pt_struct

%% Parameters
overwrite = 0;

%% Get file locs
locations = cceps_files;
data_folder = [locations.main_folder,'data/'];
ieeg_folder = locations.ieeg_folder;
script_folder = locations.script_folder;
pwfile = locations.pwfile;
login_name = locations.loginname;

%% Add paths
addpath(genpath(ieeg_folder));
addpath(genpath(script_folder));

if exist([data_folder,'pt.mat'],'file') ~= 0
    %% Load data file
    pt = load([data_folder,'pt.mat']);
    pt = pt.pt;

    %% Remove dangling patients
    npts = length(pt);
    for i = npts:-1:1
        if isempty(pt(i).ieeg)
            pt(i) = [];
        else
            break
        end
    end

    if overwrite == 1
        p = 1;
    else
        p = length(pt) + 1; % start at next index of pt struct
    end
else
    p = 1;
end





%% Loop over which hospital
hospitals = {'HUP','CHOP'};
first_num = 1;
last_num = 30;

for h = 1:2
    hosp = hospitals{h};
    fprintf('\nDoing %s\n',hosp);
    
    % Loop over numbers
    i = first_num; % the HUP*** I am checking
    while 1

        % Say I have not found the patient
        found_pt = 0;

        % Base name 
        switch hosp
            case 'HUP'
                base_ieeg_name = sprintf('HUP2%d_CCEP',i);
            case 'CHOP'
                if i <10
                    base_ieeg_name = sprintf('CHOPCCEP_00%d',i);
                else
                    base_ieeg_name = sprintf('CHOPCCEP_0%d',i);
                end
        end
        

        % Try to get ieeg file with just the base name
        ieeg_name = base_ieeg_name;

        try
            session = IEEGSession(ieeg_name,login_name,pwfile);
            add_it = 1;
        catch
            if exist('session','var') ~= 0
                session.delete;
            end
            add_it = 0;
        end


        %% Add session info
        if add_it == 1
            % Name
            fname = session.data.snapName;
            switch hosp
                case 'HUP'
                    C = strsplit(fname,'_');
                    pt_name = C{1};
                case 'CHOP'
                    C = strsplit(fname,'CCEP_');
                    pt_name = [C{1},C{2}];
            end
            pt(p).name = pt_name;
            pt(p).ccep.file.fs = session.data.sampleRate;
            pt(p).ccep.file.name = session.data.snapName;
            pt(p).ccep.file.chLabels = session.data.channelLabels(:,1);
            pt(p).ccep.file.duration = session.data.rawChannels(1).get_tsdetails.getDuration/(1e6); % convert from microseconds

            % Add annotations
            n_layers = length(session.data.annLayer);

            if n_layers == 0
                pt(p).ccep.file.ann = 'empty';
            end

            for ai = 1:n_layers
                a=session.data.annLayer(ai).getEvents(0);
                n_ann = length(a);
                for k = 1:n_ann
                    event(k).start = a(k).start/(1e6);
                    event(k).stop = a(k).stop/(1e6); % convert from microseconds
                    event(k).type = a(k).type;
                    event(k).description = a(k).description;
                end
                ann.event = event;
                ann.name = session.data.annLayer(ai).name;
                pt(p).ccep.file.ann(ai) = ann;
            end

            found_pt = 1; % say I found the patient
        end
        
        if exist('session','var') ~= 0
            session.delete;
        end
            
        %% If it's a HUP patient, add info about the other ieeg files
        if strcmp(hosp,'HUP') && found_pt == 1
            dcount = 0;
            sub_add_it = 0;
            sub_finished = 0;
            main_base_name = [pt_name,'_phaseII'];

            while 1
                if dcount == 0
                    % Try to get ieeg file with just the base name
                    ieeg_name = main_base_name;

                    try
                        session = IEEGSession(ieeg_name,login_name,pwfile);
                        sub_finished = 1;
                        sub_add_it = 1;
                        dcount = 1;
                    catch

                        if exist('session','var') ~= 0
                            session.delete;
                        end

                    end
                else % if dcount > 0, trying appendage
                    % Try it with an appendage
                    ieeg_name = [main_base_name,'_D0',sprintf('%d',dcount)];
                    try
                        session = IEEGSession(ieeg_name,login_name,pwfile);
                        sub_finished = 0;
                        sub_add_it = 1;
                    catch
                        sub_add_it = 0;
                        sub_finished = 1; % if I can't find it adding appendage, nothing else to check
                    end

                end

                % Add session info
                if sub_add_it == 1
                    pt(p).ieeg.file(dcount).fs = session.data.sampleRate;
                    pt(p).ieeg.file(dcount).name = session.data.snapName;
                    pt(p).ieeg.file(dcount).chLabels = session.data.channelLabels(:,1);
                    pt(p).ieeg.file(dcount).duration = session.data.rawChannels(1).get_tsdetails.getDuration/(1e6); % convert from microseconds

                    % Add annotations
                    n_layers = length(session.data.annLayer);

                    if n_layers == 0
                        pt(p).ieeg.file(dcount).ann = 'empty';
                    end

                    for ai = 1:n_layers
                        a=session.data.annLayer(ai).getEvents(0);
                        n_ann = length(a);
                        for k = 1:n_ann
                            event(k).start = a(k).start/(1e6);
                            event(k).stop = a(k).stop/(1e6); % convert from microseconds
                            event(k).type = a(k).type;
                            event(k).description = a(k).description;
                        end
                        ann.event = event;
                        ann.name = session.data.annLayer(ai).name;
                        pt(p).ieeg.file(dcount).ann(ai) = ann;
                    end

                end

                % done
                if sub_finished == 1
                    if exist('session','var') ~= 0
                        session.delete;
                    end
                    break % break out of ieeg loop for that patient
                end

                dcount = dcount + 1; % if not finished, see if another appendage
                if exist('session','var') ~= 0
                    session.delete;
                end


            end
        end

     
        % advance pt index if I did find it
        if found_pt == 1
            % Save the file
            save([data_folder,'pt.mat'],'pt');
            p = p + 1;
        end

        % advance count regardless
        i = i + 1;
        if i > last_num
            break
        end
        
        if exist('session','var') ~= 0
            session.delete;
        end
    end
end

end
