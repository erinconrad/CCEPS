function [atob,btoa] = reconcile_two_labels(labA,labB)

[~,btoa] = ismember(labA,labB);
[~,atob] = ismember(labB,labA);

end