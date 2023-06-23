function get_aic_model

%% Load pretty cceps
cT = readtable('steve.csv');

%% Get variable names (the different cceps waveforms)
var_names = cT.Properties.VariableNames;

%% Get the waveform you want
for iv = 1:2%length(var_names)
    curr_var = var_names{iv};

    voltage_old = cT.(curr_var); % change Varn to try different ccep waveforms
    
    %% Restrict time of waveform to fit
    fs = 1024;
    voltage = voltage_old(500:750); % could adjust this range
    time = (1:length(voltage))'/fs*1000;
    
    %% Establish initial parameters
    p0 = [35 75 min(voltage),...
        25 100 max(voltage),...
        27 135 min(voltage),...
        30 220 max(voltage),...
        40 250 max(voltage)];
    
    %% Define anonymous function to minimize, calls gamma_function_arbitrary_number
    myFx = @(p) sqrt(sum((voltage' - gamma_function_arbitrary_number_inscript(time,p)).^2));
    
    %% Loop over 1-5 possible gamma functions, calculate AIC
    ngammas = 5;
    all_yFit = nan(ngammas,length(time));
    all_L = nan(ngammas,1);
    all_aic = nan(ngammas,1);
    for ig = 1:ngammas
        curr_p0 = p0(1:ig*3);
        Mdl_param = fmincon(myFx,curr_p0,[],[],[],[]);
        all_yFit(ig,:) = gamma_function_arbitrary_number_inscript(time,Mdl_param);
    
        resid = all_yFit(ig,:)-voltage';
        all_L(ig) = max_log_likelihood(resid,length(time));
        %{
        all_L(ig) = (length(time)*log(2*pi) + length(time) + ...
            length(time)*log(sum(resid.^2)/length(time)))/(-2);
        %}
        all_aic(ig) = 2*length(curr_p0) - 2*all_L(ig);
    end
    
    %% Plot it
    figure
    set(gcf,'position',[10 10 1300 800])
    
    for ig = 1:ngammas
        nexttile
        plot(time,voltage,'k','linewidth',2)
        hold on
        plot(time,all_yFit(ig,:),'--','linewidth',2)
        xlabel('Time (ms)')
        title(sprintf('%d gammas, AIC: %1.f',ig,all_aic(ig)))
        set(gca,'fontsize',15)
    end
    nexttile
    plot(1:ngammas,all_aic,'k-o','markersize',10,'linewidth',2)
    xlabel('Number of gammas')
    ylabel('AIC')
    title('AIC by number of gamma functions')
    set(gca,'fontsize',15)

end

end

% calculates maximum log likelihood assuming gaussian noise
function ll = max_log_likelihood(resid,n)
% https://en.wikipedia.org/wiki/Maximum_likelihood_estimation
ll = -n/2*(log(2*pi*1/n*sum(resid.^2))+1);

end

function vep_fit = gamma_function_arbitrary_number_inscript(time,p)
% This lets you calculate the gamma function model for an arbitrary number
% of gamma functions

assert(mod(length(p),3)==0) % p must be divisible by 3
nfunctions = length(p)/3; % how many gamma functions

gamma = nan(nfunctions,length(time));

for ig = 1:nfunctions
    n = p((ig-1)*3+1);
    t = p((ig-1)*3+2)/n;
    a = p((ig-1)*3+3);
    c = 1/max((time.^n).*exp(-time./t));

    for i = 1:length(time)
        gamma(ig,i) = c*(time(i)^n)*exp(-time(i)/t);
    end
    gamma(ig,:) = a*gamma(ig,:)./max(gamma(ig,:));
end

vep_fit = sum(gamma,1);

end