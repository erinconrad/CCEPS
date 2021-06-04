function avg_pc = calc_pc(values,fs,tw)

nchs = size(values,2);

%% Define time windows
iw = tw*fs;
window_start = 1:iw:size(values,1);

% remove dangling window
if window_start(end) + iw > size(values,1)
    window_start(end) = [];
end
nw = length(window_start);


%% Calculate pc for each window
all_pc = zeros(nchs*(nchs-1)/2,nw);
for i = 1:nw
    clip = values(window_start:window_start+iw,:);
    pc = zeros(nchs,nchs);
    
    
    for ich = 1:nchs
        for jch = 1:ich-1 % check that this is the right num to loop through
            
            % pearson correlation
            r = corr(clip(:,ich),clip(:,jch));
            
            pc(ich,jch) = r;
            pc(jch,ich) = r;
        end
    end
    
    if 0
        figure
        imagesc(pc(:,:))
        pause
        close(gcf)
    end
    
    %% unwrap the pc matrix into a one dimensional vector for storage
    all_pc(:,i) = wrap_or_unwrap_adjacency(pc);
    
    
end

%% Average the network over all time windows
avg_pc = nanmean(all_pc,2);

end