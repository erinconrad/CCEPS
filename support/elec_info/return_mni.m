function out = return_mni(name,elec_loc_folder)

elec_file = 'electrodenames_coordinates_mni.csv';
anat_file = 'electrodenames_native';

listing = dir(elec_loc_folder);
match_idx = [];

for i = 1:length(listing)
    if contains(listing(i).name,name)
        match_idx = [match_idx;i];
    end
end

if isempty(match_idx)
    fprintf('\nWarning, no folder match for %s\n',name);
    out = [];
    return
else
    fprintf('\nGetting elec locs for %s\n',name);
end

for i = 1:length(match_idx)
    
    which_index = match_idx(i);

    %% Load the desired file
    try
        T = readtable([elec_loc_folder,listing(which_index).name,'/',elec_file]);
    catch
        
        try % also try the subfolder with the patient's RID
            folder_name = listing(which_index).name;
            C = strsplit(folder_name,'_');
            rid = C{1};
            
            T = readtable([elec_loc_folder,listing(which_index).name,'/',...
                rid,'/',elec_file]);
            
        catch
            
            fprintf('\nWarning, no file match for %s\n',name);
        
            out(i).folder_name = listing(which_index).name;
            out(i).elec_names = [];
            out(i).locs = [];
            out(i).anatomy = [];

            continue
            
        end
               
        
    end
    
    if ~ismember(T.Properties.VariableNames,'Var1')
        out(i).folder_name = listing(which_index).name;
        out(i).elec_names = [];
        out(i).locs = [];
        out(i).anatomy = [];
        continue
    end

    %% Get electrode names
    elec_names = T.Var1;
    locs = [T.Var2 T.Var3 T.Var4];

    %% Do some sanity checks
    % Are the elec names strings
    if ~iscell(elec_names)
        error('check elec names');
    end

    if ~strcmp(class(elec_names{1}),'char')
        error('check elec names');
    end
    
    % Is the median distance between electrodes and the one listed under them
    % close to 5 mm?
    %{
    diff_locs = diff(locs,[],1);
    dist_locs = vecnorm(diff_locs,2,2);
    if abs(median(dist_locs)-5) > 0.1
        error('check distances');
    end
    %}
    out(i).folder_name = listing(which_index).name;
    out(i).elec_names = elec_names;
    out(i).locs = locs;
    
    %% Also add anatomy
    % Load the desired file
    try
        T = readtable([elec_loc_folder,listing(which_index).name,'/',anat_file],...
            'readvariablenames',false);
    catch
        
        try % also try the subfolder with the patient's RID
            folder_name = listing(which_index).name;
            C = strsplit(folder_name,'_');
            rid = C{1};
            
            T = readtable([elec_loc_folder,listing(which_index).name,'/',...
                rid,'/',anat_file],'readvariablenames',false);
            
        catch
            
            fprintf('\nWarning, no file match for %s\n',name);
        
            out(i).anatomy = [];

            continue
            
        end
               
        
    end
    
    %% Get elec names
    elec_names_ana = T.Var1;
    
    if size(T,2) >1
        elec_ana = T.Var2;
    else
        elec_ana = cell(size(elec_names_ana));
    end
    
    %% Reconcile two sets of electrode names
    [lia,locb] = ismember(elec_names,elec_names_ana);
    ana = cell(length(elec_names),1);
    ana(lia) = elec_ana(locb(lia));
    
    if ~isequal(elec_names,elec_names_ana)
        table(elec_names,elec_names_ana,ana)
        error('look');
    end
    
    out(i).anatomy = ana;
    
end


end