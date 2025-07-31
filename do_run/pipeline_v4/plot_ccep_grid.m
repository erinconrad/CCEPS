function plot_ccep_grid(pt_out, stimPairs, respPairs, useStored)
% plot_ccep_grid  –  Grid of trial‑averaged CCEP waveforms
%
%   plot_ccep_grid(pt_out, stimPairs, respPairs)
%   plot_ccep_grid(pt_out, stimPairs, respPairs, useStored)
%
% INPUTS
%   pt_out     : structure from pipeline_v4/v5 or GUI‑edited copy
%   stimPairs  : cell array of bipolar stim labels (row order)
%   respPairs  : cell array of bipolar response labels (col order)
%   useStored  : logical (default false)
%                • false → ignore pt_out.elecs.*.N1/N2, auto‑detect peaks
%                • true  → use stored latencies if finite, else auto
%
% FEATURES
%   • Blue N1 ● / line, red N2 ▲ / line, matching GUI colours
%   • Baseline window (‑100 to ‑5 ms) dotted at axis top
%   • z‑scores (relative to baseline) annotated per tile
%   • Legend showing N1 vs N2 markers below grid

if nargin < 4, useStored = false; end
plot_markers = true;      %

% ----------------------------------------------------------------------
% Colour constants (MATLAB defaults)
blue = [0    0.45 0.74];    % N1
red  = [0.85 0.33 0.10];    % N2

% ----------------------------------------------------------------------
fs = pt_out.other.stim.fs;

% map bipolar label → index
labMap = containers.Map( ...
            cellfun(@char, pt_out.bipolar_labels(:),'Uni',0), ...
            1:numel(pt_out.bipolar_labels));

stimIdx = cellfun(@(sp) find(strcmp(pt_out.chLabels, strtok(sp,'-')),1), ...
                  stimPairs,'Uni',1);
respIdx = cellfun(@(rp) labMap(rp), respPairs,'Uni',1);

% ----------------------------------------------------------------------
% Gather waveforms & time vectors
allW = cell(numel(stimPairs), numel(respPairs));
allT = cell(size(allW));
yMin=inf; yMax=-inf; xMin=inf; xMax=-inf;

for s = 1:numel(stimPairs)
    if isnan(stimIdx(s)), continue; end
    elec = pt_out.elecs(stimIdx(s));

    base_t = (0:size(elec.avg,1)-1)/fs;           % seconds
    if isfield(elec,'times') && ~isempty(elec.times)
        base_t = base_t + elec.times(1);
    else
        base_t = base_t - 0.5;                     % default start -500 ms
    end
    t_ms = base_t*1000;

    for r = 1:numel(respPairs)
        if isnan(respIdx(r)), continue; end
        w = elec.avg(:, respIdx(r));
        allW{s,r}=w; allT{s,r}=t_ms;
        yMin=min(yMin,min(w)); yMax=max(yMax,max(w));
        xMin=min(xMin,t_ms(1)); xMax=max(xMax,t_ms(end));
    end
end

yLim = [-300 300];
xLim = [xMin xMax];

% ----------------------------------------------------------------------
% Plot grid
% ----------------------------------------------------------------------
figure('Position',[79 60 1350 800]);
tl = tiledlayout(numel(stimPairs), numel(respPairs), ...
                 'TileSpacing','compact','Padding','compact');

for s = 1:numel(stimPairs)
    for r = 1:numel(respPairs)

        ax = nexttile;
        lat1_in = pt_out.elecs(stimIdx(s)).N1(respIdx(r));
        lat2_in = pt_out.elecs(stimIdx(s)).N2(respIdx(r));
        fprintf('GRID INPUT  %s ↔ %s   N1 %.1f   N2 %.1f\n', ...
                stimPairs{s}, respPairs{r}, lat1_in, lat2_in);


        if isempty(allW{s,r}), axis off; continue; end

        w = allW{s,r};
        t = allT{s,r};

        plot(t,w,'LineWidth',2,'Color','k'); hold on
        xline(0,'k:','LineWidth',2); yline(0,'k:','LineWidth',2);
        ylim(yLim); xlim(xLim); set(gca,'FontSize',20)

        % Baseline stats & indicator
        bl_idx = t>=-100 & t<=-5;
        mu  = mean(w(bl_idx),'omitnan');
        sig = std( w(bl_idx),'omitnan');
        y_vis = yLim(2)-0.05*range(yLim);
        plot([-100 -5],[y_vis y_vis],'k:','LineWidth',1.2);

        % ----- choose N1 latency ---------------------------------------
        lat1 = pt_out.elecs(stimIdx(s)).N1(respIdx(r));
        if ~(useStored && isfinite(lat1))
            win = find(t>=15 & t<50);
            [~,ii]=max(abs(w(win)-mu)); lat1=t(win(ii));
        end

        % ----- choose N2 latency ---------------------------------------
        lat2 = pt_out.elecs(stimIdx(s)).N2(respIdx(r));
        if ~(useStored && isfinite(lat2))
            win = find(t>=50 & t<=200);
            [~,ii]=max(abs(w(win)-mu)); lat2=t(win(ii));
        end

        fprintf('PRE PLOT  %s ↔ %s   N1 %.1f   N2 %.1f\n', ...
                stimPairs{s}, respPairs{r}, lat1, lat2);

        % ----- plot markers + z‑scores ---------------------------------
        if plot_markers
            [~,i1]=min(abs(t-lat1)); z1=(w(i1)-mu)/sig;
            [~,i2]=min(abs(t-lat2)); z2=(w(i2)-mu)/sig;

            plot(lat1,w(i1),'o','MarkerFaceColor',blue,'MarkerEdgeColor','k','MarkerSize',5);
            plot(lat2,w(i2),'^','MarkerFaceColor',red ,'MarkerEdgeColor','k','MarkerSize',5);
            xline(lat1,'--','Color',blue,'LineWidth',0.8);
            xline(lat2,'--','Color',red ,'LineWidth',0.8);

            txt = sprintf('N1 z=%.1f, %1.0f ms\\newlineN2 z=%.1f, %1.0f ms',z1,lat1,z2,lat2);
            text(0.98,0.94, txt, 'Units','normalized', ...
                 'HorizontalAlign','right','VerticalAlign','top', ...
                 'FontSize',20);
        end

        % outer labels
        if s==numel(stimPairs), xlabel(['Resp: ' respPairs{r}],'Interpreter','none'); end
        if r==1, ylabel(['Stim: ' stimPairs{s}],'Interpreter','none'); end
        set(ax,'TickDir','out','Box','off');
    end
end
xlabel(tl,'Time (ms)','FontSize',20);
ylabel(tl,'Amplitude (\muV)','FontSize',20);

% ----------------------------------------------------------------------
% Legend (blue N1, red N2) beneath grid
% ----------------------------------------------------------------------
hN1 = plot(nan,nan,'o','MarkerFaceColor',blue,'MarkerEdgeColor','k','MarkerSize',6);
hN2 = plot(nan,nan,'^','MarkerFaceColor',red,'MarkerEdgeColor','k','MarkerSize',7);

lgd = legend([hN1 hN2], {'N1 (15–50 ms)','N2 (50–200 ms)'}, ...
             'Orientation','horizontal', 'Location','southoutside');
lgd.Box = 'off';

end
