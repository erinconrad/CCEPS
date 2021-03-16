function ana = get_abbreviations(ana)

add_side = 0;

for ich = 1:length(ana)
    abb = [];
    full_name = ana{ich};
    
    if isempty(full_name), continue; end
    
    if contains(full_name,'hippocampus')
        abb = 'HIPP';%'hippocampus';%'posterior\newlinehippocampus';
    elseif contains(full_name,'amygdala')
        abb = 'AM';%'amygdala';
    elseif contains(full_name,'anterior insula')
        abb = 'AI';%{'anterior','insula'};
    elseif contains(full_name,'central sulcus')
        abb = 'CS';%{'central','sulcus'};
    elseif contains(full_name,'posterior insula')
        abb = 'PI';%;{'posterior','insula'};
    elseif contains(full_name,'pars triangularis')
        abb = 'PT';%{'pars','triangularis'};
    elseif contains(full_name,'inferior frontal gyrus')
        abb = 'IFG';
    elseif contains(full_name,'anterior cingulate')
        abb = 'AC';%{'anterior','cingulate'};
    elseif contains(full_name,'middle frontal gyrus')
        abb = 'MFG';
    elseif contains(full_name,'orbitofrontal')
        abb = 'OF';
    elseif contains(full_name,'superior frontal gyrus')
        abb = 'SFG';
    elseif contains(full_name,'temporal pole')
        abb = 'TP';
    elseif contains(full_name,'mid cingulate')
        abb = 'MC';
    elseif contains(full_name,'parietal') && contains(full_name,'MEG')
        abb = 'PMEG';
    elseif contains(full_name,'frontal eye field')
        abb = 'FEF';
    elseif contains(full_name,'frontal pole')
        abb = 'FP';
    else
        C = strsplit(full_name,' ');
        side = C{1};
        side_length = length(side);
        abb = full_name;
        abb(1:side_length) = [];
        
    end
    
    if add_side
        % Get first part of full name
        C = strsplit(full_name,' ');
        side = C{1};
        if strcmp(side,'left') || strcmp(side,'Left')
            abb = ['L',abb];
        elseif strcmp(side,'right') || strcmp(side,'Right')
            abb = ['R',abb];
        else
            continue;
        end
    end
    
    ana{ich} = abb;
end    

end