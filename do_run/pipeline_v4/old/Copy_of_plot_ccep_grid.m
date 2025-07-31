function plot_ccep_grid(pt_out, stimPairs, respPairs)
% plot_ccep_grid  –  Grid of trial‑averaged CCEP waveforms
%
%   Rows   = stim pairs
%   Cols   = response pairs
%   N1 •   = max |w‑baseline| in 15‑50  ms
%   N2 ▲   = max |w‑baseline| in 50‑200 ms

plot_markers = 1;                   % set =0 to hide markers
fs           = pt_out.other.stim.fs;

% ----------------------------------------------------------------------
% 1) Map bipolar labels → indices (unchanged)
% ----------------------------------------------------------------------
raw = pt_out.bipolar_labels(:);
keys = {}; vals = [];
for c = 1:numel(raw)
    lbl = raw{c};
    if iscell(lbl) && ~isempty(lbl), lbl = lbl{1}; end
    if isstring(lbl), lbl = char(lbl); end
    if ischar(lbl) && ~isempty(lbl)
        keys{end+1} = lbl;  vals(end+1) = c; %#ok<AGROW>
    end
end
[uniqKeys, ia] = unique(keys,'stable');
respMap = containers.Map(uniqKeys, vals(ia));

chLab = pt_out.chLabels;
stimIdx = cellfun(@(sp) find(strcmp(chLab, strtok(sp,'-')),1,'first'), ...
                  stimPairs, 'Uni',1);
respIdx = cellfun(@(rp) respMap(rp), respPairs, 'Uni',1);

% ----------------------------------------------------------------------
% 2) Gather waveforms / times, build global limits (unchanged logic)
% ----------------------------------------------------------------------
allW = cell(numel(stimPairs), numel(respPairs));
allT = cell(size(allW));
yMin = inf; yMax = -inf; xMin = inf; xMax = -inf;

for s = 1:numel(stimPairs)
    if isnan(stimIdx(s)), continue; end
    elec = pt_out.elecs(stimIdx(s));

    if isfield(elec,'times') && ~isempty(elec.times)
        base_t_ms = elec.times(:)'*1000;
    else
        base_t_ms = (0:size(elec.avg,1)-1)/fs*1000;
    end

    for r = 1:numel(respPairs)
        if isnan(respIdx(r)), continue; end
        w = elec.avg(:, respIdx(r));
        if isempty(w), continue; end

        len = numel(w);
        if numel(base_t_ms) < len        % timeline shorter than data
            t_local = base_t_ms(1) + (0:len-1)/fs*1000;
        else
            t_local = base_t_ms(1:len);
        end

        allW{s,r} = w;
        allT{s,r} = t_local;
        yMin = min(yMin, min(w)); yMax = max(yMax, max(w));
        xMin = min(xMin, t_local(1));    xMax = max(xMax, t_local(end));
    end
end
yLim = [-300 300];                      % fixed as in your snippet
xLim = [xMin xMax];

% ----------------------------------------------------------------------
% 3) Plot grid
% ----------------------------------------------------------------------
figure('Position',[79 60 1350 800]);
tl = tiledlayout(numel(stimPairs), numel(respPairs), ...
                 'TileSpacing','compact','Padding','compact');

% --- snippet: replace the plotting loop inside plot_ccep_grid -----------
for s = 1:numel(stimPairs)
    for r = 1:numel(respPairs)
        ax = nexttile;
        if isempty(allW{s,r}), axis off; continue; end

        w = allW{s,r};  t = allT{s,r};
        plot(t, w,'LineWidth',2); hold on
        xline(0,'k:','LineWidth',2); yline(0,'k:','LineWidth',2);
        ylim(yLim); xlim(xLim); set(gca,'FontSize',20)

        % ------------ BASELINE window & stats ---------------------------
        bl_idx = find(t >= -200 & t <= -10);
        baseline_mu  = mean(w(bl_idx),'omitnan');
        baseline_sig = std( w(bl_idx),'omitnan');

        % dotted horizontal baseline line
        y_bl_vis = yLim(2) - 0.05*range(yLim);      % 5 % below top
        plot([-200 -10], [y_bl_vis y_bl_vis], 'g:', 'LineWidth',2);

        % ------------ N1 (15‑50 ms) -------------------------------------
        n1_z = NaN;
        n1_win = find(t >= 15 & t < 50);
        if ~isempty(n1_win)
            [~, n1_rel_idx] = max(abs(w(n1_win) - baseline_mu));
            idx1 = n1_win(n1_rel_idx);
            x1   = t(idx1);  y1 = w(idx1);
            n1_z = (y1 - baseline_mu) / baseline_sig;
            plot(x1, y1,'ko','MarkerFaceColor','k','MarkerSize',5);
            xline(x1,'k--','LineWidth',0.8);
        end

        % ------------ N2 (50‑200 ms) ------------------------------------
        n2_z = NaN;
        n2_win = find(t >= 50 & t <= 200);
        if ~isempty(n2_win)
            [~, n2_rel_idx] = max(abs(w(n2_win) - baseline_mu));
            idx2 = n2_win(n2_rel_idx);
            x2   = t(idx2);  y2 = w(idx2);
            n2_z = (y2 - baseline_mu) / baseline_sig;
            plot(x2, y2,'k^','MarkerFaceColor','k','MarkerSize',5);
            xline(x2,'k--','LineWidth',0.8);
        end

        % ------------ annotate z‑scores ---------------------------------
        if ~isnan(n1_z) || ~isnan(n2_z)
            txt = sprintf('N1 z=%.1f\\newlineN2 z=%.1f', n1_z, n2_z);
            text(0.98,0.95, txt, 'Units','normalized', ...
                 'HorizontalAlign','right','VerticalAlign','top', ...
                 'FontSize',12,'Interpreter','tex');
        end

        % outer labels
        if s==numel(stimPairs), xlabel(['Resp: ' respPairs{r}], 'Interpreter','none'); end
        if r==1, ylabel(['Stim: ' stimPairs{s}], 'Interpreter','none'); end
        set(ax,'TickDir','out','Box','off');
    end
end

xlabel(tl,'Time (ms)','FontSize',20);
ylabel(tl,'Amplitude (\muV)','FontSize',20);
end
