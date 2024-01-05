%% Plot manual PPV and NPV

clear
close all

rng

jitter = 0.05;

locations = cceps_files;

% Load the manual validation file
T = readtable([locations.results_folder,'validation/Manual validation.xlsx']);

name = T.Subject;
ppv = T.PositivePredictiveValue;
npv = T.NegativePredictiveValue;

hup = contains(name,'HUP');
pts = (hup&~isnan(ppv)&~isnan(npv));
npts = sum(pts);

% plot the hup patients
figure
plot(ones(npts,1)+randn(npts,1)*jitter,ppv(pts),'o','color',[0, 0.4470, 0.7410],...
    'linewidth',2)
hold on
plot([0.8 1.2],[median(ppv,1,'omitmissing') median(ppv,1,'omitmissing')],...
    'LineWidth',2,'color',[0, 0.4470, 0.7410])
plot(ones(npts,1)*2+randn(npts,1)*jitter,npv(pts),'o','color',[0.8500, 0.3250, 0.0980],...
   'linewidth',2)
plot([1.8 2.2],[median(npv,1,'omitmissing') median(npv,1,'omitmissing')],...
    'LineWidth',2,'color',[0.8500, 0.3250, 0.0980])
xticks([1 2])
xticklabels({'PPV','NPV'})
ylabel('Value')
ylim([0 1.1])
title('Accuracy of automated CCEP detection')
set(gca,'fontsize',20)
print(gcf,[locations.results_folder,'validation/ppv_npv_plot'],'-dpng');

fprintf('\nThe median PPV is %1.3f and NPV is %1.3f.\n',median(ppv,1,'omitmissing'),...
    median(npv,1,'omitmissing'))