clear all; close all; clc
%% parc test
A = reshape(1:25,5,5)'; % mock matrix
parc = [1 1 2 2 3]; % mock parcellation
N = length(A);
nparc = length(unique(parc)); % number of rois
A_parc_int_rows = nan(nparc,N);
A_parc_int_cols = nan(N,nparc);
A_parc_rows = nan(nparc);
A_parc_cols = nan(nparc);

f=figure;
subplot(3,2,1);
imagesc(A); colorbar; axis square;
title('A');

subplot(3,2,3);
for roi = 1:nparc
    A_parc_int_rows(roi,:) = mean(A(parc==roi,:),1);
end
imagesc(A_parc_int_rows); colorbar; axis square;
title('rows first');

subplot(3,2,4);
for roi = 1:nparc
    A_parc_rows(:,roi) = mean(A_parc_int_rows(:,parc==roi),2);
end
imagesc(A_parc_rows); colorbar; axis square;
title('final - rows first');

subplot(3,2,5);
for roi = 1:nparc
    A_parc_int_cols(:,roi) = mean(A(:,parc==roi),2);
end
imagesc(A_parc_int_cols); colorbar; axis square;
title('cols first');

subplot(3,2,6);
for roi = 1:nparc
    A_parc_cols(roi,:) = mean(A_parc_int_cols(parc==roi,:),1);
end
imagesc(A_parc_cols); colorbar; axis square;
title('final - cols first');
