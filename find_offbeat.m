function final_arts = find_offbeat(arts,allowable_nums,goal_diff,max_off)

%{
Idea is that I will loop through allowable_nums and for all n artifacts
look at all n choose allowable_nums possible sets. I will see if I can get
them to fit the beat. If not, I will move to the next. If nothing works, I
will throw an error

Expect allowable nums will be [30, 29] (allow one dropped beat)
%}

fake_beat = 1:10;
fake_beat = [fake_beat,7.5];
fake_beat = sort(fake_beat);

found_it = 0;
good_set = 0;

allowable_nums = sort(allowable_nums,'descend');

for i = 1:length(allowable_nums)
    
    % Get all possible sets of this length
    C = nchoosek(1:length(arts),allowable_nums(i));
    
    % Loop through all of these sets
    for j = 1:size(C,1)
        
        
        
        set = arts(C(j,:));
        
       
        
        set_diff = diff(set);
        
        % see if any difference is outside the allowable range
        out_of_range = any(set_diff > goal_diff + max_off | set_diff < goal_diff - max_off);
        
        if out_of_range == 0
            found_it = 1;
            good_set = C(j,:);
            break
        end
        
        
        
    end
    
    if found_it == 1
        break
    end
end

if found_it == 0
    error('Did not find it');
end

final_arts = arts(good_set);

% Confirm that the 

end