function o = isempty_c(carr)

% INPUTS:
% carr: cellarray
%
% OUTPUTS:
% o: logical array corresponding to elements of carr indicating whether it
% is empty
%
% this is a wrapper function

o = cellfun(@isempty,carr,'UniformOutput',true);

