stim = out.other.stim;
elecs = out.elecs;
chLabels = out.chLabels;
if isfield(out,'ana')
    ana = out.ana;
end
dataName = out.name;
nchs = size(chLabels,1);
if isfield(out,'clinical')
    clinical = out.clinical;
end
bipolar_labels = out.bipolar_labels;
bipolar_ch_pair = out.bipolar_ch_pair;
dataName = out.name;

if isfield(out,'A')
    A = out.A;
    ch_info = out.ch_info;
end