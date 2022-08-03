function add_pts_to_struct(ieeg_nums,overwrite)

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
    
    if overwrite == 1
        p = 1;
    else
        p = length(pt) + 1; % start at next index of pt struct
    end
else
    p = 1;
end

for i = ieeg_nums
    ieeg_name = sprintf('HUP%d',i);
    skip = 0;
    
    %% See if we've already done it
    if exist('pt','var')
        for ip = 1:length(pt)
            if strcmp(ieeg_name,pt(ip).name)

                if overwrite == 0
                    fprintf('\nAlready have %s, skipping...\n',ieeg_name);
                    skip = 1;
                    break
                end
            end
        end
    end
    if skip == 1
        continue
    end
    
    %% Attempt to find it on ieeg.org and get the number of files
    base_ieeg_name = sprintf('HUP%d_CCEP',i);
    ieeg_names = {};
    try session = IEEGSession(base_ieeg_name,login_name,pwfile);
        nfiles = 1;
        ieeg_names = {base_ieeg_name};
        session.delete;
    catch
        if exist('session','var') ~= 0
            session.delete;
        end
        
        % Try adding an appendage
        app = 1;
        nfiles = 0;
        while 1
            temp_ieeg_name = sprintf('%s_0%d',base_ieeg_name,app);
            try session = IEEGSession(temp_ieeg_name,login_name,pwfile);
                nfiles = nfiles+1;
                ieeg_names = [ieeg_names,temp_ieeg_name];
                app = app+1;
                session.delete;
            catch
                if exist('session','var') ~= 0
                    session.delete;
                end
                break
            end
            
        end
        
    end
   
       
    %% Add session info
    if nfiles == 0
        fprintf('\nDid not find %s, skipping...\n',ieeg_name);
        continue
    end
    for f = 1:nfiles
        fname = ieeg_names{f};
        session = IEEGSession(fname,login_name,pwfile);
        pt_name = ieeg_name;
        fprintf('\nDoing %s file %d...\n',ieeg_name,f);
        
        pt(p).name = pt_name;
        pt(p).ccep.file(f).fs = session.data.sampleRate;
        pt(p).ccep.file(f).name = session.data.snapName;
        pt(p).ccep.file(f).chLabels = session.data.channelLabels(:,1);
        pt(p).ccep.file(f).duration = session.data.rawChannels(1).get_tsdetails.getDuration/(1e6); % convert from microseconds

        % Add annotations
        clear event
        n_layers = length(session.data.annLayer);

        if n_layers == 0
            pt(p).ccep.file(f).ann = 'empty';
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
            pt(p).ccep.file(f).ann(ai) = ann;
        end

        found_pt = 1; % say I found the patient
        if exist('session','var') ~= 0
            session.delete;
        end
    end

    

   

    % advance pt index if I did find it
    if found_pt == 1
        % Save the file
        save([data_folder,'pt.mat'],'pt');
        p = p + 1;
    end


    if exist('session','var') ~= 0
        session.delete;
    end
    
    
end


end
