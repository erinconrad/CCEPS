function pt_out = pt_pipeline_v2(filenames,login_name,pwfile,ignore_elecs)

% tell if it's multiple files or 1
if iscell(filenames)
    mult_files = 1;
    nfiles = length(filenames);
else
    mult_files = 0;
    nfiles = 1;
end

all_out = cell(nfiles,1);
for f = 1:nfiles

    if mult_files == 1
        filename = filenames{f};
    else
        filename = filenames;
    end

    % Do the file loop
    all_out{f} = filename_pipeline_v2(filename,login_name,pwfile,ignore_elecs);


end

% if multiple files, stitch the output structures together
if mult_files
    pt_out = stitch_outputs(all_out);
else
    pt_out = all_out{1};
end


end