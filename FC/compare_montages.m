function compare_montages(pout)

%% Get various path locations
locations = cceps_files; % Need to make a file pointing to you own path
script_folder = locations.script_folder;
results_folder = locations.results_folder;

% add paths
addpath(genpath(script_folder));


bipolar = pout.bipolar_pc;
machine = pout.machine_pc;
car = pout.car_pc;

figure
tiledlayout(2,3)

nexttile
turn_nans_white_ccep(machine)
title('Machine')

nexttile
turn_nans_white_ccep(car)
title('CAR')

nexttile
turn_nans_white_ccep(bipolar)
title('Bipolar')

nexttile
plot(nansum(machine,1),nansum(car,1),'o')
xlabel('Machine')
ylabel('CAR')

nexttile
plot(nansum(machine,1),nansum(bipolar,1),'o')
xlabel('Machine')
ylabel('Bipolar')

nexttile
plot(nansum(bipolar,1),nansum(car,1),'o')
xlabel('Bipolar')
ylabel('CAR')

end