function plot_ccep_grid(pt_out, stimPairs, respPairs)
% plot_ccep_grid  –  Grid of trial‑averaged CCEP waveforms
%
%   Rows   = stim pairs  (Stim: xxx‑xxx)
%   Columns= response pairs (Resp: xxx‑xxx)
%
% Features
%   • Handles empty / unequal‑length waveforms gracefully
%   • Uniform y‑axis across all tiles
%   • Uniform x‑axis (based on global min/max time across plotted waves)
%   • N1 marker  ●,  N2 marker  ▲   (dashed vertical lines at latencies)
%   • Outer‑edge axes labelled with "Stim:" and "Resp:"
%
% Usage
%   plot_ccep_grid(pt_out, {'LG1-LG2','LF1-LF2'}, {'LG5-LG6','LG6-LG7'})

% ----------------------------------------------------------------------
% 1) Build a bipolar‑label → column index map (skip empties)
% ----------------------------------------------------------------------
raw = pt_out.bipolar_labels(:);
keys = {}; vals = [];
for c = 1:numel(raw)
    lbl = raw{c};
    if iscell(lbl) && ~isempty(lbl), lbl = lbl{1}; end
    if isstring(lbl),   lbl = char(lbl); end
    if ischar(lbl) && ~isempty(lbl)
        keys{end+1} = lbl; %#ok<AGROW>
        vals(end+1) = c;   %#ok<AGROW>
    end
end
[uniqKeys, ia] = unique(keys,'stable');
respMap = containers.Map(uniqKeys, vals(ia));

% helper: stim index = first contact of pair
chLab   = pt_out.chLabels;
fs      = pt_out.other.stim.fs;

stimIdx = nan(numel(stimPairs),1);
for k = 1:numel(stimPairs)
    stimIdx(k) = find(strcmp(chLab, strtok(stimPairs{k},'-')), 1);
end
respIdx = nan(numel(respPairs),1);
for k = 1:numel(respPairs)
    if respMap.isKey(respPairs{k})
        respIdx(k) = respMap(respPairs{k});
    end
end

% ----------------------------------------------------------------------
% 2) Gather waveforms, time vectors, and global axes limits
% ----------------------------------------------------------------------
allW  = cell(numel(stimPairs), numel(respPairs));
allT  = cell(size(allW));
yMin  =  inf;  yMax = -inf;
xMin  =  inf;  xMax = -inf;

for s = 1:numel(stimPairs)
    if isnan(stimIdx(s)), continue; end

    % use times vector if present, else build from fs
    if isfield(pt_out.elecs(stimIdx(s)), 'times') && ...
            ~isempty(pt_out.elecs(stimIdx(s)).times)
        base_t = pt_out.elecs(stimIdx(s)).times(:)';        % row vector
    else
        nSamp  = size(pt_out.elecs(stimIdx(s)).avg,1);
        base_t = (0:nSamp-1)/fs;
    end
    base_t_ms = base_t*1000;   % convert once here

    for r = 1:numel(respPairs)
        if isnan(respIdx(r)), continue; end

        w = pt_out.elecs(stimIdx(s)).avg(:, respIdx(r));
        if isempty(w), continue; end

        len = numel(w);
        if numel(base_t_ms) >= len
        % full timeline stored – just truncate
        t_local = base_t_ms(1:len);
    else
        % only start/end stored – synthesize timeline from fs
        t_start = base_t_ms(1);
        t_local = t_start + (0:len-1)/fs*1000;   % ms
    end


        allW{s,r} = w;
        allT{s,r} = t_local;

        yMin = min(yMin, min(w));
        yMax = max(yMax, max(w));
        xMin = min(xMin, t_local(1));
        xMax = max(xMax, t_local(end));
    end
end
yLim = [yMin yMax];
xLim = [xMin xMax];

% ----------------------------------------------------------------------
% 3) Plot grid
% ----------------------------------------------------------------------
tiledlayout(numel(stimPairs), numel(respPairs), ...
            'TileSpacing','compact','Padding','compact');

for s = 1:numel(stimPairs)
    for r = 1:numel(respPairs)
        ax = nexttile;
        if isempty(allW{s,r})
            axis off; continue;
        end

        w = allW{s,r};
        t = allT{s,r};
        plot(t, w, 'LineWidth',1); hold on
        xline(0,'k:');  yline(0,'k:');
        ylim(yLim); xlim(xLim);

        % ---------- N1 marker ---------------------------------------------------
        n1_val = pt_out.elecs(stimIdx(s)).N1(respIdx(r));   % could be index *or* ms
        if ~isnan(n1_val) && n1_val > 0
            if abs(n1_val - round(n1_val)) < 1e-6 && n1_val <= numel(w)
                % stored as sample index
                idx   = round(n1_val);
                x_n1  = t(idx);      y_n1 = w(idx);
            else
                % stored as latency in ms
                x_n1  = n1_val;
                [~,idx] = min(abs(t - x_n1));   % nearest point for y‑value
                y_n1  = w(idx);
            end
            plot(x_n1, y_n1, 'ko', 'MarkerFaceColor','k', 'MarkerSize',4);
            xline(x_n1, 'k--', 'LineWidth',0.5);
        end
        
        % ---------- N2 marker ---------------------------------------------------
        n2_val = pt_out.elecs(stimIdx(s)).N2(respIdx(r));
        if ~isnan(n2_val) && n2_val > 0
            if abs(n2_val - round(n2_val)) < 1e-6 && n2_val <= numel(w)
                idx   = round(n2_val);
                x_n2  = t(idx);      y_n2 = w(idx);
            else
                x_n2  = n2_val;
                [~,idx] = min(abs(t - x_n2));
                y_n2  = w(idx);
            end
            plot(x_n2, y_n2, 'k^', 'MarkerFaceColor','k', 'MarkerSize',4);
            xline(x_n2, 'k--', 'LineWidth',0.5);
        end


        % --- outer labels only ----------------------------------------
        if s == numel(stimPairs)
            xlabel(['Resp: ' respPairs{r}], 'Interpreter','none');
        end
        if r == 1
            ylabel(['Stim: ' stimPairs{s}], 'Interpreter','none');
        end
        set(ax,'TickDir','out','Box','off');
    end
end
sgtitle('Trial‑averaged CCEP waveforms');
end
