function [stim,response] = get_stim_response_elecs(A)


stim = repmat(1:size(A,2),size(A,1),1);
response = repmat((1:size(A,1))',1,size(A,2));



end