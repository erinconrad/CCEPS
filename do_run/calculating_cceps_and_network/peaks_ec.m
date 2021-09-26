function [loc,amp]=peaks_ec(s)
ds=diff(s);
ds=[ds(1);ds];%pad diff
filter=find(ds(2:end)==0)+1;%%find zeros
ds(filter)=ds(filter-1);%%replace zeros
ds=sign(ds);
ds=diff(ds);
loc=find(ds<0);
amp = s(loc);

end