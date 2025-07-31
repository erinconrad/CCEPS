function ccep_step_gui(pt_out, stimPairs, respPairs)
% CCEP_STEP_GUI  –  step‑through viewer for CCEP waveforms with draggable
%                   N1 / N2 markers and one‑click export to the full grid.
%
% Usage:
%   ccep_step_gui(pt_out, stimPairs, respPairs)
%
% • Prev / Next buttons (or ← / → keys) cycle through every combination.
% • Drag either marker to update its latency and z‑score.
% • Baseline window = –100 to –5 ms; z = (peak – μ_baseline) / σ_baseline.
% • Export Grid recreates the full matrix using adjusted markers.

% ------------------------------------------------------------------------
% 0) Pre‑compute mapping indices and storage matrices
% ------------------------------------------------------------------------
fs     = pt_out.other.stim.fs;
chLab  = pt_out.chLabels;

stimIdx = cellfun(@(sp) find(strcmp(chLab, strtok(sp,'-')), 1, 'first'), ...
                  stimPairs, 'Uni', 1);

respMap = containers.Map( ...
            cellfun(@char, pt_out.bipolar_labels(:), 'Uni', 0), ...
            1:numel(pt_out.bipolar_labels));

respIdx = cellfun(@(rp) respMap(rp), respPairs, 'Uni', 1);

nStim   = numel(stimPairs);
nResp   = numel(respPairs);
total   = nStim * nResp;
pos     = 1;                                   % current position

% matrices to store adjusted latencies (milliseconds)
N1_lat  = nan(nStim, nResp);
N2_lat  = nan(nStim, nResp);

% ------------------------------------------------------------------------
% 1) GUI scaffold
% ------------------------------------------------------------------------
fig = uifigure('Name','CCEP Step‑through GUI','Position',[100 100 1000 650]);

ax  = uiaxes(fig,'Position',[50 140 900 440]); hold(ax,'on');
xlabel(ax,'Time (ms)'); ylabel(ax,'Amplitude (\muV)'); ax.FontSize = 14;

btnPrev   = uibutton(fig,'Text','←  Prev','Position',[250 50 100 40], ...
                     'ButtonPushedFcn',@(~,~) step(-1));
btnNext   = uibutton(fig,'Text','Next  →','Position',[650 50 100 40], ...
                     'ButtonPushedFcn',@(~,~) step(+1));
btnExport = uibutton(fig,'Text','Export Grid','Position',[450 50 120 40], ...
                     'ButtonPushedFcn',@(~,~) exportGrid());

statusL = uilabel(fig,'Position',[380 50 60 40],'FontSize',14, ...
                  'HorizontalAlignment','center');
n1L     = uilabel(fig,'Position',[800 50 90 40],'FontSize',14);
n2L     = uilabel(fig,'Position',[890 50 90 40],'FontSize',14);

% store shared handles/data
S = struct('ax',ax,'fs',fs,'stimIdx',stimIdx,'respIdx',respIdx, ...
           'stimPairs',{stimPairs},'respPairs',{respPairs}, ...
           'N1',N1_lat,'N2',N2_lat,'pos',pos,'total',total);
guidata(fig,S);

% keyboard navigation
fig.KeyPressFcn = @(~,evt) ...
    (strcmp(evt.Key,'rightarrow')*step(+1) + ...
     strcmp(evt.Key,'leftarrow')  *step(-1));

draw();   % initial waveform
% ------------------------------------------------------------------------

    % ====================================================== nested funcs
    function step(delta)
        S = guidata(fig);
        S.pos  = mod(S.pos-1 + delta, S.total) + 1;   % wrap 1…total
        guidata(fig,S);
        draw();
    end

    function draw()
        S = guidata(fig);
        [sIdx, rIdx] = ind2sub([nStim nResp], S.pos);

        % update status label
        statusL.Text = sprintf('%d / %d', S.pos, S.total);

        % fetch waveform
        elec = pt_out.elecs(S.stimIdx(sIdx));
        if isfield(elec,'times') && ~isempty(elec.times)
            t0_ms = elec.times(1)*1000;               % start time
        else
            t0_ms = -500;
        end
        w = elec.avg(:, S.respIdx(rIdx)).';
        t = t0_ms + (0:numel(w)-1)/S.fs*1000;

        % clear axes & plot waveform
        cla(S.ax);
        S.hWave = plot(S.ax,t,w,'LineWidth',2); hold(S.ax,'on');
        xline(S.ax,0,'k:','LineWidth',2); yline(S.ax,0,'k:','LineWidth',2);
        ylim(S.ax,[-300 300]); xlim(S.ax,[min(t) max(t)]);

        % baseline indicator (top 5 % of y‑axis)
        y_lim = ylim(S.ax);
        y_vis = y_lim(2) - 0.05*range(y_lim);
        plot(S.ax,[-100 -5],[y_vis y_vis],'k:','LineWidth',1.2);

        % baseline stats
        bl_idx = t>=-100 & t<=-5;
        mu  = mean(w(bl_idx),'omitnan');
        sig = std( w(bl_idx),'omitnan');

        % default markers
        [n1_t, n2_t] = defaultMarkers(t,w,mu);

        % override with previous edits if they exist
        if ~isnan(S.N1(sIdx,rIdx)), n1_t = S.N1(sIdx,rIdx); end
        if ~isnan(S.N2(sIdx,rIdx)), n2_t = S.N2(sIdx,rIdx); end

        % draggable lines
        blue   = [0    0.45 0.74];      % MATLAB default blue
        red    = [0.85 0.33 0.10];      % MATLAB default red
        
        S.n1Line = drawline(S.ax,'Position',[n1_t -300; n1_t 300], ...
                            'Color', blue, 'LineWidth',1.5);
        S.n2Line = drawline(S.ax,'Position',[n2_t -300; n2_t 300], ...
                            'Color', red , 'LineWidth',1.5);
        
        S.n1Pt   = scatter(S.ax, n1_t, interp1(t,w,n1_t), 60, ...
                           'o', 'MarkerFaceColor', blue, 'MarkerEdgeColor', 'k');
        S.n2Pt   = scatter(S.ax, n2_t, interp1(t,w,n2_t), 80, ...
                           '^', 'MarkerFaceColor', red , 'MarkerEdgeColor', 'k');

        addlistener(S.n1Line,'ROIMoved',@(~,~) recalc());
        addlistener(S.n2Line,'ROIMoved',@(~,~) recalc());

        guidata(fig,S);
        recalc();   % compute initial z‑scores
    end

    function recalc()
        S = guidata(fig);
        [sIdx, rIdx] = ind2sub([nStim nResp], S.pos);
        t = S.hWave.XData;  w = S.hWave.YData;

        % baseline stats
        bl_idx = t>=-100 & t<=-5;
        mu  = mean(w(bl_idx),'omitnan');
        sig = std( w(bl_idx),'omitnan');

        % N1
        n1_t = S.n1Line.Position(1,1);
        [~,idx1] = min(abs(t-n1_t)); y1 = w(idx1);
        n1_z = (y1-mu)/sig;
        S.n1Pt.XData = n1_t; S.n1Pt.YData = y1;
        n1L.Text = sprintf('N1 z = %.2f', n1_z);

        % N2
        n2_t = S.n2Line.Position(1,1);
        [~,idx2] = min(abs(t-n2_t)); y2 = w(idx2);
        n2_z = (y2-mu)/sig;
        S.n2Pt.XData = n2_t; S.n2Pt.YData = y2;
        n2L.Text = sprintf('N2 z = %.2f', n2_z);

        % store latencies
        S.N1(sIdx,rIdx) = n1_t;
        S.N2(sIdx,rIdx) = n2_t;
        guidata(fig,S);
    end

    function exportGrid()
        S = guidata(fig);
        pt_mod = pt_out;    % shallow copy
        for si = 1:nStim
            sI = S.stimIdx(si);
            for ri = 1:nResp
                rI = S.respIdx(ri);
                pt_mod.elecs(sI).N1(rI) = S.N1(si,ri);
                pt_mod.elecs(sI).N2(rI) = S.N2(si,ri);
            end
        end
        plot_ccep_grid(pt_mod, stimPairs, respPairs,true);
    end

    function [n1_t, n2_t] = defaultMarkers(t,w,mu)
        n1_win = find(t>=15 & t<50);
        [~,i1] = max(abs(w(n1_win)-mu)); n1_t = t(n1_win(i1));
        n2_win = find(t>=50 & t<=200);
        [~,i2] = max(abs(w(n2_win)-mu)); n2_t = t(n2_win(i2));
    end
end
