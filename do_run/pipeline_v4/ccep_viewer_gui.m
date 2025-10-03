function ccep_viewer_gui(pt_in, stimPairs, respPairs)
% 1) Compute automatic N1/N2 (15-50 ms, 50-200 ms) every launch
pt = recompute_peaks(pt_in, stimPairs, respPairs);

% --- session-level save directory (remembered until function exits)
saveDir = '../../../results/TCEPs_review/';  % set via "Choose Save Folder" or on first save

% 2) Viewer ------------------------------------------------------------
ui = uifigure('Name','CCEP Grid','Position',[60 60 1250 860]);

% 2 rows: grid + buttons
mainLayout = uigridlayout(ui, [2 1]);
mainLayout.RowHeight = {'1x', 50};
mainLayout.ColumnWidth = {'1x'};

% Row 1: Grid panel
panel = uipanel(mainLayout);
panel.Layout.Row = 1;
panel.Layout.Column = 1;

% Row 2: Button row -> 3 columns
btnRow = uigridlayout(mainLayout,[1 3]);
btnRow.Layout.Row = 2;
btnRow.Layout.Column = 1;
btnRow.ColumnWidth = {200, 200, '1x'};

% Buttons
btnAdjust = uibutton(btnRow, 'Text', 'Adjust Peaks', ...
    'ButtonPushedFcn', @(~,~) openEditor());
btnAdjust.Layout.Column = 1;

btnSave = uibutton(btnRow, 'Text', 'Save PNG (Grid)', ...
    'ButtonPushedFcn', @(~,~) saveGridPng());
btnSave.Layout.Column = 2;

btnChoose = uibutton(btnRow, 'Text', 'Choose Save Folder', ...
    'ButtonPushedFcn', @(~,~) chooseSaveDir());
btnChoose.Layout.Column = 3;

% Grid for plots
grid = uigridlayout(panel);
drawGrid();

    function drawGrid()
        delete(grid.Children);  % clear old axes but keep layout
        nS = numel(stimPairs);
        nR = numel(respPairs);

        grid.RowHeight = repmat({"1x"},1,nS);
        grid.ColumnWidth = repmat({"1x"},1,nR);

        plot_ccep_grid(pt, stimPairs, respPairs, true, grid);
    end

    function openEditor()
        pt_new = peak_editor(pt, stimPairs, respPairs);
        if ~isempty(pt_new), pt = pt_new; drawGrid(); end
    end

    function chooseSaveDir()
        d = uigetdir(pwd,'Choose folder to save PNGs');
        if ischar(d) || (isstring(d) && strlength(d)>0) %#ok<ISSTR>
            saveDir = char(d);
            uialert(ui, sprintf('Saving to:\n%s', saveDir), 'Save Folder Set', 'Icon','success');
        end
    end

    function saveGridPng()
        if isempty(saveDir)
            chooseSaveDir();
            if isempty(saveDir), return; end
        end
        ts = datestr(now,'yyyymmdd_HHMMSS');
        fname = fullfile(saveDir, sprintf('ccep_grid_%s.png', ts));
    
        try
            drawnow;
    
            % 1) Find axes under the grid panel (both types)
            axUI_panel = findall(panel, 'Type','uiaxes');
            axHG_panel = findall(panel, 'Type','axes');
    
            % If panel has none, look in the whole app window as a fallback
            if isempty(axUI_panel) && isempty(axHG_panel)
                axUI_all = findall(ui, 'Type','uiaxes');
                axHG_all = findall(ui, 'Type','axes');
                axUI = axUI_all;
                axHG = axHG_all;
            else
                axUI = axUI_panel;
                axHG = axHG_panel;
            end
    
            if isempty(axUI) && isempty(axHG)
                error('No axes (uiaxes or axes) found under panel or figure.');
            end
    
            % Combine into one list (preserve a sensible row-major order)
            % For uiaxes we can sort by Layout.Row/Column when present.
            orderKeys = [];
            axList = [axUI(:); axHG(:)];
    
            orderKeys = zeros(numel(axList),1);
            for k = 1:numel(axList)
                a = axList(k);
                try
                    % Try UI grid coordinates first (works for uiaxes in uigridlayout)
                    r = a.Layout.Row; c = a.Layout.Column;
                    orderKeys(k) = r*1e3 + c;
                catch
                    % Fallback: sort by position on screen (row-major: top->bottom, left->right)
                    p = get(a,'Position'); % [x y w h] in pixels
                    orderKeys(k) = -p(2)*1e3 + p(1); % y descending, x ascending
                end
            end
            [~,ord] = sort(orderKeys);
            axList = axList(ord);
    
            % Infer a grid: if you know nS/nR, use them; else make a near-square tiling
            nS = numel(stimPairs);
            nR = numel(respPairs);
            if numel(axList) ~= nS*nR
                % fallback: approximate square
                n = numel(axList);
                nS = floor(sqrt(n));
                nR = ceil(n / nS);
            end
    
            % 2) Hidden classic figure & tiledlayout
            f = figure('Visible','off','Color','w','Position',[100 100 1600 1000]);
            tl = tiledlayout(f, nS, nR, 'TileSpacing','compact', 'Padding','compact');
    
            % 3) Copy objects from each source axes to the new classic axes
            for k = 1:numel(axList)
                axSrc = axList(k);
                axNew = nexttile(tl, k);
                hold(axNew,'on');
    
                % Copy graphic children
                ch = allchild(axSrc);
                if ~isempty(ch), copyobj(ch, axNew); end
    
                % Copy common properties (best effort)
                try, xlim(axNew, xlim(axSrc)); end
                try, ylim(axNew, ylim(axSrc)); end
                try, title(axNew, axSrc.Title.String); end
                try, xlabel(axNew, axSrc.XLabel.String); end
                try, ylabel(axNew, axSrc.YLabel.String); end
                box(axNew,'on'); axis(axNew,'tight');
            end
    
            % 4) Save
            try
                exportgraphics(f, fname, 'Resolution', 300, 'BackgroundColor','white');
            catch
                print(f, fname, '-dpng', '-r300');
            end
            delete(f);
    
            uialert(ui, sprintf('Saved:\n%s', fname), 'PNG Saved', 'Icon','success');
    
        catch ME
            uialert(ui, sprintf('Could not save PNG:\n%s', ME.message), 'Save Error', 'Icon','error');
        end
    end



end

% ======================================================================
function pt_out = recompute_peaks(pt, stimPairs, respPairs)
fs  = pt.other.stim.fs; ch = pt.chLabels;
sIdx = cellfun(@(s)find(strcmp(ch,strtok(s,'-')),1), stimPairs);
map  = containers.Map(cellfun(@char,pt.bipolar_labels(:),'Uni',0),1:numel(pt.bipolar_labels));
rIdx = cellfun(@(r)map(r), respPairs);
for s = 1:numel(stimPairs)
    elec = pt.elecs(sIdx(s));
    t0 = (isfield(elec,'times')&&~isempty(elec.times))*elec.times(1)*1000 + ...
        (~isfield(elec,'times')||isempty(elec.times))*-500;
    for r = 1:numel(respPairs)
        w = elec.avg(:,rIdx(r));
        t = t0 + (0:numel(w)-1)/fs*1000;
        mu = mean(w(t>=-100 & t<=-5),'omitnan');
        % N1
        w1 = find(t>=15 & t<50);
        [~,i1]=max(abs(w(w1)-mu)); pt.elecs(sIdx(s)).N1(rIdx(r))=t(w1(i1));
        % N2
        w2 = find(t>=50 & t<=200);
        [~,i2]=max(abs(w(w2)-mu)); pt.elecs(sIdx(s)).N2(rIdx(r))=t(w2(i2));
    end
end
pt_out = pt;
end

% ======================================================================
function pt_out = peak_editor(pt, stimPairs, respPairs)
fs  = pt.other.stim.fs; ch = pt.chLabels;
sIdx = cellfun(@(s)find(strcmp(ch,strtok(s,'-')),1), stimPairs);
map  = containers.Map(cellfun(@char,pt.bipolar_labels(:),'Uni',0),1:numel(pt.bipolar_labels));
rIdx = cellfun(@(r)map(r), respPairs);

nS=numel(stimPairs); nR=numel(respPairs); tot=nS*nR; pos=1;
N1 = nan(nS,nR);
N2 = nan(nS,nR);
for ss = 1:nS
    for rr = 1:nR
        N1(ss,rr) = pt.elecs(sIdx(ss)).N1(rIdx(rr));
        N2(ss,rr) = pt.elecs(sIdx(ss)).N2(rIdx(rr));
    end
end

fig = uifigure('Name','Adjust Peaks','WindowStyle','modal','Position',[120 120 1000 730]);
ax = uiaxes(fig,'Position',[60 180 880 500]); hold(ax,'on');

% --- editor button row
btnRow = uigridlayout(fig,[1 4]);
btnRow.RowHeight = {40};
btnRow.ColumnWidth = {120, 120, 160, '1x'};
btnRow.Position = [60 70 880 40];

uibutton(btnRow,'Text','← Prev', 'ButtonPushedFcn',@(~,~) step(-1));
uibutton(btnRow,'Text','Next →', 'ButtonPushedFcn',@(~,~) step(+1));
uibutton(btnRow,'Text','Back to Grid','ButtonPushedFcn',@(~,~) closeModal());

% New: save current trace PNG
uibutton(btnRow,'Text','Save PNG (This Plot)','ButtonPushedFcn',@(~,~) saveEditorPng());

lbl=uilabel(fig,'Position',[400 140 200 24],'HorizontalAlignment','center');

draw(); uiwait(fig);  % blocks

    function step(d), pos=mod(pos-1+d,tot)+1; draw(); end

    function draw()
        [si,ri]=ind2sub([nS nR],pos); lbl.Text=sprintf('%d/%d',pos,tot);
        elec=pt.elecs(sIdx(si)); t0=(isfield(elec,'times')&&~isempty(elec.times))*elec.times(1)*1000 + ...
            (~isfield(elec,'times')||isempty(elec.times))*-500;
        w=elec.avg(:,rIdx(ri))'; t=t0+(0:numel(w)-1)/fs*1000;
        cla(ax); plot(ax,t,w,'k','LineWidth',2); xline(ax,0,'k:'); yline(ax,0,'k:');
        ylim(ax,[-100 100]); xlim(ax,[-200 500])
        n1=N1(si,ri); n2=N2(si,ri);
        ln1=drawline(ax,'Position',[n1 -100; n1 100],'Color',[0 0.45 0.74]);
        ln2=drawline(ax,'Position',[n2 -100; n2 100],'Color',[0.85 0.33 0.10]);
        iS = si;   iR = ri;
        addlistener(ln1,'ROIMoved',@(src,~) updateLat(src,true ,iS,iR));
        addlistener(ln2,'ROIMoved',@(src,~) updateLat(src,false,iS,iR));

        function updateLat(src,isN1,ss,rr)
            newLat = src.Position(1,1);
            if isN1, N1(ss,rr) = newLat; else, N2(ss,rr) = newLat; end
        end
    end

    function saveEditorPng()
        d = uigetdir(pwd,'Choose folder to save PNG');
        if isequal(d,0); return; end
    
        [si,ri] = ind2sub([nS nR],pos);
        clean = @(s) regexprep(s,'[^A-Za-z0-9\-]+','_');
        stimStr = clean(stimPairs{si});
        respStr = clean(respPairs{ri});
        ts = datestr(now,'yyyymmdd_HHMMSS');
        fname = fullfile(d, sprintf('ccep_%s__%s_%s.png', stimStr, respStr, ts));
    
        try
            drawnow;
    
            % Clone UIAxes to classic figure
            f = figure('Visible','off','Color','w','Position',[200 200 1000 600]);
            axNew = axes('Parent', f); hold(axNew,'on');
    
            ch = allchild(ax);
            if ~isempty(ch)
                copyobj(ch, axNew);
            else
                error('No graphics objects found in editor axes.');
            end
    
            % Copy properties
            try
                xlim(axNew, xlim(ax));
                ylim(axNew, ylim(ax));
            end
            try, title(axNew, ax.Title.String); end
            try, xlabel(axNew, ax.XLabel.String); end
            try, ylabel(axNew, ax.YLabel.String); end
            box(axNew,'on');
    
            % Save
            try
                exportgraphics(f, fname, 'Resolution', 300, 'BackgroundColor','white');
            catch
                print(f, fname, '-dpng', '-r300');
            end
    
            delete(f);
            uialert(fig, sprintf('Saved:\n%s', fname), 'PNG Saved', 'Icon','success');
    
        catch ME
            uialert(fig, sprintf('Could not save PNG:\n%s', ME.message), ...
                'Save Error', 'Icon','error');
        end
    end



    function closeModal()
        for si=1:nS
            for ri=1:nR
                pt.elecs(sIdx(si)).N1(rIdx(ri)) = N1(si,ri);
                pt.elecs(sIdx(si)).N2(rIdx(ri)) = N2(si,ri);
            end
        end
        pt_out = pt; delete(fig);
    end
end
