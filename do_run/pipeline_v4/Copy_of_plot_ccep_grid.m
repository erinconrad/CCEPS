function plot_ccep_grid(pt_out, stimPairs, respPairs)
% plot_ccep_grid  Plot trial‑averaged CCEP waveforms in an nStim × nResp grid
%
% INPUTS
%   pt_out     – struct saved by pipeline_v4/v5 (contains .elecs, .chLabels …)
%   stimPairs  – 1×nStim cell array of bipolar stim labels, e.g. {'LA1‑LA2', …}
%   respPairs  – 1×nResp cell array of bipolar response labels
%
% USAGE
%   S  = load('HUP123.mat');                % S.pt_out
%   plot_ccep_grid(S.pt_out, {'LA1‑LA2','LB3‑LB4'}, {'RA1‑RA2','RB1‑RB2'},);
%

%% ------------------------------------------------------------------ helpers
chLab     = pt_out.chLabels;          % monopolar labels
fs        = pt_out.other.stim.fs;     % sampling rate


% ------------------------------------------------------------------------
% Build a clean label→column map from pt_out.bipolar_labels
% ------------------------------------------------------------------------
raw  = pt_out.bipolar_labels(:);      % mixed types
keys = {};                            % labels (char row vectors)
vals = [];                            % corresponding column indices

for c = 1:numel(raw)
    lbl = raw{c};

    % unwrap nested cells
    if iscell(lbl) && ~isempty(lbl)
        lbl = lbl{1};
    end

    % normalise to char text
    if isstring(lbl),   lbl = char(lbl); end

    if ischar(lbl) && ~isempty(lbl)
        keys{end+1} = lbl;             %#ok<AGROW>
        vals(end+1) = c;               %#ok<AGROW>
    end
end

% ensure keys are unique (Map requires this)
[uniqKeys, ia] = unique(keys,'stable');   % keep first occurrence
uniqVals       = vals(ia);

respMap = containers.Map(uniqKeys , uniqVals);

% stim electrodes are stored monopolar; take the *first* contact of the pair
stimIdx   = nan(numel(stimPairs),1);
for k = 1:numel(stimPairs)
    toks       = strsplit(stimPairs{k},'-');
    stimIdx(k) = find(strcmp(chLab, toks{1}), 1);
    if isempty(stimIdx(k))
        warning('Stim %s not found – skipping row', stimPairs{k});
    end
end

respIdx   = nan(numel(respPairs),1);
for k = 1:numel(respPairs)
    if respMap.isKey(respPairs{k})
        respIdx(k) = respMap(respPairs{k});
    else
        warning('Resp %s not found – skipping column', respPairs{k});
    end
end

%% ------------------------------------------------------------------ plot
tiledlayout(numel(stimPairs), numel(respPairs), ...
            'TileSpacing','compact','Padding','compact');

for s = 1:numel(stimPairs)
    if isnan(stimIdx(s)), continue; end
    % pull once per stim row to get length/time
    wavLen = size(pt_out.elecs(stimIdx(s)).avg,1);
    t_ms   = (0:wavLen-1)/fs*1000 + pt_out.elecs(stimIdx(s)).times(1)*1000;
    
    for r = 1:numel(respPairs)
        ax = nexttile;
        if isnan(respIdx(r)), axis off; continue; end
        
        w = pt_out.elecs(stimIdx(s)).avg(:, respIdx(r));  % waveform :contentReference[oaicite:3]{index=3}
        plot(t_ms, w, 'LineWidth',1);
        xline(0,'k:');  yline(0,'k:');
        xlim([t_ms(1) t_ms(end)]);
        
        % annotate only the outer edges
        if s == numel(stimPairs)
            xlabel(respPairs{r}, 'Interpreter','none');
        end
        if r == 1
            ylabel(stimPairs{s}, 'Interpreter','none');
        end
        set(ax, 'TickDir','out', 'Box','off');
    end
end

sgtitle('Trial‑averaged CCEP waveforms');
end
