function [elecs,contacts] = return_contact_and_electrode(labels)

elecs = cell(length(labels),1);
contacts = nan(length(labels),1);

for i = 1:length(labels)
    curr = labels{i};
    a = regexp(curr,'\d*');
    
    num = str2num(curr(a:end));
    name = curr(1:a-1);
    
    elecs{i} = name;
    
    if ~isempty(num)
        contacts(i) = num;
    end
    
    
end

end