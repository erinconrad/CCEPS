function ch = name_to_ch(name,out)
    labels = out.chLabels;
    ch = find(strcmp(name,labels));
end