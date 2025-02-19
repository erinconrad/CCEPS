function matching_hup = rid_to_hup(rid)

locations = cceps_files;
data_folder = locations.data_folder;
T = readtable([data_folder,'rid_hup.csv']);
hup = T.hupsubjno;
record_id = T.record_id;

if length(rid) > 1
    matching_hup = nan(length(rid),1);
    for i = 1:length(rid)
        r = record_id == rid(i);
        matching_hup(i) = hup(r);
    end
else
    r = record_id == rid;
    matching_hup = hup(r);
end

end