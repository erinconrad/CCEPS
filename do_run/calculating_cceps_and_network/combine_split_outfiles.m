function out = combine_split_outfiles(outstruct)
% Expects outstruct, which is a substructure made like this: 
% outstruct(1) = out1; outstruct(2) = out2; etc, where out1 and out2 are
% the broken up out files
% Should tolerate any number of out files
% ToDo: add checks for missing data?

out = outstruct(1).out; %initialize to out1 to get size/shape etc
for j = 1:length(outstruct)
    stimNidx = outstruct(j).out.stim_chs;  %pick out chans stimmed in each outstruct.out
    out.elecs(stimNidx) = outstruct(j).out.elecs(stimNidx);  %load them into out
    out.other.periods(stimNidx) = outstruct(j).out.other.periods(stimNidx)
    out.other.stim_elecs = [out.other.stim_elecs; outstruct(j).out.other.stim_elecs];
    out.stim_chs = out.stim_chs+outstruct(j).out.stim_chs;
    if j~=1 & all(size(out.avg_pc) == size(outstruct(j).out.avg_pc))
        out.avg_pc = out.avg_pc + outstruct(j).out.avg_pc;
    end
end

out.other.stim_elecs = sort(unique(out.other.stim_elecs));
out.stim_chs(out.stim_chs>1) = 1; % clean up any duplicated stim chans
% don't need to update response channels, these are the same


for w = 1:2
    temp = [];
    for j = 1:length(outstruct)
        temp(:,:,j) = outstruct(j).out.rejection_details(w).reject.sig_avg; 
    end
    temp = sum(temp,3,'omitnan'); 
    temp(all(isnan(temp),3)) = NaN;   %summing with omit nan replaces NaN with 0's, so have to add back if they were all NaN
    out.rejection_details(w).reject.sig_avg = temp;

    temp = [];
    for j = 1:length(outstruct)
        temp(:,:,j) = outstruct(j).out.rejection_details(w).reject.pre_thresh; 
    end
    temp = sum(temp,3,'omitnan'); 
    temp(all(isnan(temp),3)) = NaN;   %summing with omit nan replaces NaN with 0's, so have to add back if they were all NaN
    out.rejection_details(w).reject.pre_thresh = temp;

    temp = [];
    for j = 1:length(outstruct)
        temp(:,:,j) = outstruct(j).out.rejection_details(w).reject.at_thresh; 
    end
    temp = sum(temp,3,'omitnan'); 
    temp(all(isnan(temp),3)) = NaN;   %summing with omit nan replaces NaN with 0's, so have to add back if they were all NaN
    out.rejection_details(w).reject.at_thresh = temp;

    temp = [];
    for j = 1:length(outstruct)
        temp(:,:,j) = outstruct(j).out.rejection_details(w).reject.keep; 
    end
    temp = sum(temp,3,'omitnan'); 
    temp(all(isnan(temp),3)) = NaN;   %summing with omit nan replaces NaN with 0's, so have to add back if they were all NaN
    out.rejection_details(w).reject.keep = temp;
        
    temp = [];
    for j = 1:length(outstruct)
        temp(:,:,j) = outstruct(j).out.network(w).A; 
    end
    temp = sum(temp,3,'omitnan'); 
    temp(all(isnan(temp),3)) = NaN;   %summing with omit nan replaces NaN with 0's, so have to add back if they were all NaN
    out.network(w).A = temp;

        temp = [];
    for j = 1:length(outstruct)
        temp(:,:,j) = outstruct(j).out.network(w).A; 
    end
    temp = sum(temp,3,'omitnan'); 
    temp(all(isnan(temp),3)) = NaN;   %summing with omit nan replaces NaN with 0's, so have to add back if they were all NaN
    out.network(w).A = temp;

end
