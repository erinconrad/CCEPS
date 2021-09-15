function avg_pc = calc_pc(values,fs,tw)

%{
This calculates Pearson connectivity measurements
%}

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
all_pc = zeros(nchs,nchs,nw);

% I am trying to parallelize this part
for i = 1:nw
    clip = values(window_start:window_start+iw,:);
        
    pc = corrcoef(clip);
    pc(logical(eye(size(pc)))) = 0;
    
    all_pc(:,:,i) = pc;
end

%% Average the network over all time windows
avg_pc = nanmean(all_pc,3);

end