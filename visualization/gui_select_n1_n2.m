function cceps = gui_select_n1_n2(cceps)

%% Parameters
overwrite = 0; % don't start from scratch each time you run this

%{
This function takes a bunch of cceps waveforms, plots them, asks you to
select the N1 and N2 if they exist, and then outputs the amplitude and lag
of each waveform in the original structure.

Input:
- cceps: a structure that should be of the form cceps.data(n).data. n
should be the number of cceps waveforms and data(i).data should be an
n_samples x 1 array showing a single ccep waveform

Output:
- cceps: the same structure with 3 fields added:
   - next_one: an index of the first unfinished waveform
   - n1: an nx2 array showing the time lag (in samples) and amplitude of
   the N1
   - n2: same but for n2

%}
   
% load eeg data
n_cceps = length(cceps.data);

% Load it if it exists to see how much we've already done
if overwrite == 0
    if isfield(cceps,'next_one') 
        
       
    else
        cceps.next_one = 1;
        cceps.n1 = nan(n_cceps,2);
        cceps.n2 = nan(n_cceps,2);
    end
else
    
    cceps.next_one = 1;
    cceps.n1 = nan(n_cceps,2);
    cceps.n2 = nan(n_cceps,2);
end

% loop through spikes
for s = cceps.next_one:n_cceps
    
    fprintf('Doing CCEP %d of %d...\n',s,n_cceps);
    
    % get eeg data
    data = cceps.data(s).data; % ntimes x nch
    
    % plot the cceps
    figure
    plot(data);

    
    title(sprintf('CCEP %d of %d',s,n_cceps),'fontsize',15)

    % Get N1
    fprintf('Select the N1 and press Enter. If no N1, press Enter.\n');
    try
        [x,y] = ginput;
    catch
        return
    end

    if isempty(x)
    else
        cceps.n1(s,:) = [x(end) y(end)];
    end

    % Get N2
    fprintf('Select the N2 and press Enter. If no N2, press Enter.\n');
    try
        [x,y] = ginput;
    catch
        return
    end
    if isempty(x)
    else
        cceps.n2(s,:) = [x(end) y(end)];
    end
    cceps.next_one = s+1;
    
    
    close(gcf)
    
    
end
    
    
end



function FigHandle = figure2(varargin)
MP = get(0, 'MonitorPositions');
if size(MP, 1) == 1  % Single monitor
  FigH = figure(varargin{:});
else                 % Multiple monitors
  % Catch creation of figure with disabled visibility: 
  indexVisible = find(strncmpi(varargin(1:2:end), 'Vis', 3));
  if ~isempty(indexVisible)
    paramVisible = varargin(indexVisible(end) + 1);
  else
    paramVisible = get(0, 'DefaultFigureVisible');
  end
  %
  Shift    = MP(2, 1:2);
  FigH     = figure(varargin{:}, 'Visible', 'off');
  drawnow;
  set(FigH, 'Units', 'pixels');
  pos      = get(FigH, 'Position');
  pause(0.02);  % See Stefan Glasauer's comment
  set(FigH, 'Position', [pos(1:2) + Shift, pos(3:4)], ...
            'Visible', paramVisible);
end
if nargout ~= 0
  FigHandle = FigH;
end

end

