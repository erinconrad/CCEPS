function AUC = plot_roc(labels,scores,posclass)

% INPUTS:
% labels: ground truth labels
% scores: probability of belonging to positive class
% posclass: entry corresponding to positive class in labels
%
% OUTPUTS:
% plots on figure
% AUC: area under the curve
[X,Y,T,AUC] = perfcurve(labels,scores,posclass);

plot(X,Y);
xlabel('False positive rate') 
ylabel('True positive rate')