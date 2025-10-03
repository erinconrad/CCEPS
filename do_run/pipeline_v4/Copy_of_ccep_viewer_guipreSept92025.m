function ccep_viewer_gui(pt_in, stimPairs, respPairs)
% 1) Compute automatic N1/N2 (15-50 ms, 50-200 ms) every launch
pt = recompute_peaks(pt_in, stimPairs, respPairs);

% 2) Viewer ------------------------------------------------------------
ui = uifigure('Name','CCEP Grid','Position',[60 60 1250 860]);

mainLayout = uigridlayout(ui, [2 1]);  % 2 rows: grid + button
mainLayout.RowHeight = {'1x', 50};     % top resizes, bottom is 50 px
mainLayout.ColumnWidth = {'1x'};

% Row 1: Grid panel
panel = uipanel(mainLayout);
panel.Layout.Row = 1;
panel.Layout.Column = 1;

nS = numel(stimPairs);
nR = numel(respPairs);
%{
grid = uigridlayout(panel, [nS nR], ...
    'RowHeight', repmat({"1x"}, 1, nS), ...
    'ColumnWidth', repmat({"1x"}, 1, nR));
%}

% Row 2: Button
btn = uibutton(mainLayout, ...
    'Text', 'Adjust Peaks', ...
    'ButtonPushedFcn', @(~,~) openEditor());

btn.Layout.Row = 2;
btn.Layout.Column = 1;


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

uibutton(fig,'Text','← Prev','Position',[220 70 120 40],...
    'ButtonPushedFcn',@(~,~) step(-1));
uibutton(fig,'Text','Next →','Position',[660 70 120 40],...
    'ButtonPushedFcn',@(~,~) step(+1));
uibutton(fig,'Text','Back to Grid','Position',[440 70 120 40],...
    'ButtonPushedFcn',@(~,~) closeModal());

lbl=uilabel(fig,'Position',[400 70 80 40],'HorizontalAlignment','center');

draw(); uiwait(fig);  % blocks

    function step(d), pos=mod(pos-1+d,tot)+1; draw(); end

    function draw()
        [si,ri]=ind2sub([nS nR],pos); lbl.Text=sprintf('%d/%d',pos,tot);
        elec=pt.elecs(sIdx(si)); t0=(isfield(elec,'times')&&~isempty(elec.times))*elec.times(1)*1000 + ...
            (~isfield(elec,'times')||isempty(elec.times))*-500;
        w=elec.avg(:,rIdx(ri))'; t=t0+(0:numel(w)-1)/fs*1000;
        cla(ax); plot(ax,t,w,'k','LineWidth',2); xline(ax,0,'k:'); yline(ax,0,'k:');
        ylim(ax,[-100 100]); %xlim(ax,[min(t) max(t)]);
        xlim(ax,[-200 500])
        n1=N1(si,ri); n2=N2(si,ri);
        ln1=drawline(ax,'Position',[n1 -100; n1 100],'Color',[0 0.45 0.74]);
        ln2=drawline(ax,'Position',[n2 -100; n2 100],'Color',[0.85 0.33 0.10]);
        % capture current indices so the callback uses the right cell
        iS = si;   iR = ri;
        
        addlistener(ln1,'ROIMoved',@(src,evt) updateLat(src,true ,iS,iR));
        addlistener(ln2,'ROIMoved',@(src,evt) updateLat(src,false,iS,iR));
        
        % nested helper -------------------------------------------
        function updateLat(src,isN1,ss,rr)
            newLat = src.Position(1,1);
            if isN1
                N1(ss,rr) = newLat;
            else
                N2(ss,rr) = newLat;
            end
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
