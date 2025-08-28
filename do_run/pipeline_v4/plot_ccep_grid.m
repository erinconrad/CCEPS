function plot_ccep_grid(pt_out, stimPairs, respPairs, useStored, grid)
% plot_ccep_grid – Grid of trial-averaged CCEP waveforms into uigridlayout
%
% Inputs:
%   pt_out     - structure with CCEP waveforms and latencies
%   stimPairs  - cell array of stim channel pairs (rows)
%   respPairs  - cell array of response channel pairs (columns)
%   useStored  - true to use stored N1/N2, false to recompute
%   grid       - uigridlayout object to draw into

if nargin < 4, useStored = false; end

% Colors
blue = [0 0.45 0.74];   % N1
red  = [0.85 0.33 0.10];% N2

fs = pt_out.other.stim.fs;

% Map bipolar label → index
labMap = containers.Map( ...
    cellfun(@char, pt_out.bipolar_labels(:), 'UniformOutput', false), ...
    1:numel(pt_out.bipolar_labels));

stimIdx = cellfun(@(sp) find(strcmp(pt_out.chLabels, strtok(sp,'-')),1), ...
                  stimPairs, 'UniformOutput', true);
respIdx = cellfun(@(rp) labMap(rp), respPairs, 'UniformOutput', true);

nS = numel(stimPairs);
nR = numel(respPairs);
yLim = [-100 100];

% Time and waveform data
allW = cell(nS, nR);
allT = cell(nS, nR);
xMin = inf; xMax = -inf;

for s = 1:nS
    if isnan(stimIdx(s)), continue; end
    elec = pt_out.elecs(stimIdx(s));

    base_t = (0:size(elec.avg,1)-1) / fs;  % seconds
    if isfield(elec, 'times') && ~isempty(elec.times)
        base_t = base_t + elec.times(1);
    else
        base_t = base_t - 0.5;  % default start at -500 ms
    end
    t_ms = base_t * 1000;

    for r = 1:nR
        if isnan(respIdx(r)), continue; end
        w = elec.avg(:, respIdx(r));
        allW{s,r} = w;
        allT{s,r} = t_ms;
        xMin = min(xMin, t_ms(1));
        xMax = max(xMax, t_ms(end));
    end
end

xLim = [xMin xMax];

% Plot each waveform
for s = 1:nS
    for r = 1:nR
        ax = uiaxes(grid);
        cla(ax);
        hold(ax, 'on');
        set(ax, 'FontSize', 12, 'Box', 'off', 'TickDir', 'out');

        if isempty(allW{s,r})
            axis(ax, 'off');
            continue;
        end

        w = allW{s,r};
        t = allT{s,r};

        % Plot waveform
        plot(ax, t, w, 'k', 'LineWidth', 2);
        xline(ax, 0, 'k:', 'LineWidth', 1);
        yline(ax, 0, 'k:', 'LineWidth', 1);
        ylim(ax, yLim);
        %xlim(ax, xLim);
        %xlim(ax,[-0.2 0.5])
        xlim(ax,[-200 500])
        % Baseline stats
        bl_idx = t >= -100 & t <= -5;
        mu = mean(w(bl_idx), 'omitnan');
        sig = std(w(bl_idx), 'omitnan');
        y_vis = yLim(2) - 0.05 * range(yLim);
        plot(ax, [-100 -5], [y_vis y_vis], 'k:', 'LineWidth', 1.2);

        % Latency selection
        lat1 = pt_out.elecs(stimIdx(s)).N1(respIdx(r));
        lat2 = pt_out.elecs(stimIdx(s)).N2(respIdx(r));

        if ~(useStored && isfinite(lat1))
            win1 = find(t >= 15 & t < 50);
            [~, ii] = max(abs(w(win1) - mu)); lat1 = t(win1(ii));
        end
        if ~(useStored && isfinite(lat2))
            win2 = find(t >= 50 & t <= 200);
            [~, ii] = max(abs(w(win2) - mu)); lat2 = t(win2(ii));
        end

        % z-scores
        [~, i1] = min(abs(t - lat1)); z1 = (w(i1) - mu) / sig;
        [~, i2] = min(abs(t - lat2)); z2 = (w(i2) - mu) / sig;

        % Plot markers
        plot(ax, lat1, w(i1), 'o', 'MarkerFaceColor', blue, 'MarkerEdgeColor', 'k', 'MarkerSize', 5);
        plot(ax, lat2, w(i2), '^', 'MarkerFaceColor', red, 'MarkerEdgeColor', 'k', 'MarkerSize', 6);
        xline(ax, lat1, '--', 'Color', blue, 'LineWidth', 1);
        xline(ax, lat2, '--', 'Color', red, 'LineWidth', 1);

        % Annotate
        txt = sprintf('N1 z=%.1f, %.0f ms\\newlineN2 z=%.1f, %.0f ms', z1, lat1, z2, lat2);
        text(ax, 0.98, 0.94, txt, 'Units', 'normalized', ...
            'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', ...
            'FontSize', 15);

        % Axis labels
        if s == nS
            xlabel(ax, ['Resp: ' respPairs{r}], 'Interpreter', 'none','FontSize',20);
        end
        if r == 1
            ylabel(ax, ['Stim: ' stimPairs{s}], 'Interpreter', 'none','FontSize',20);
        end
    end
end
end
