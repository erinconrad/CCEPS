function ana = get_abbreviations(ana)

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
    end
    
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
    
    ana{ich} = abb;
end    

end