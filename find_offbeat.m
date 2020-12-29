function final_arts = find_offbeat(arts,allowable_nums,goal_diff,max_off)

%% New way
%{
Look at first artifact (our candidate s). Then see if there are at least allowable_nums
correctly spaced from it (s, s+freq, s+2freq, etc.). If there are, this is
our s, and extra ones can be ignored. If not, move on to the 2nd artifact
as our candidate s.
%}

final_arts = [];
start = 1;
which_seq = 1;
while 1
seq = nan;

for a = start:length(arts)
    
    % candidate s (first time)
    s = arts(a);
    
    on_beat = a;
    
    % Loop through the other arts and see how many are within an allowable
    % distance
    for b = a+1:length(arts)
        
        new = arts(b);
        
        % If the two mod the goal diff aren't too far off
        if abs(mod(new-s,goal_diff)) < max_off && new-s > 100
            
            if ~isempty(on_beat)
                if abs(new-arts(on_beat(end))) < 100
                    continue
                end
            end
            
            % Add it to the number that are on beat
            on_beat = [on_beat;b];
            
        end
        
    end
    
    % Check how many are on beat
    if length(on_beat) >= min(allowable_nums)
        
        % If enough are on beat, then this is the correct sequence
        seq = on_beat;
        break
        
    end
    
    % If not enough on beat, try the next one
    
end

%if isnan(seq), error('Did not find it'); end


if isnan(seq)
    break
else
    final_arts = [final_arts;seq, which_seq*ones(size(seq,1),1)];
    % allow for possibility of multiple sequences
    start = seq(end)+1;
    which_seq = which_seq + 1;
end

end

%% Old probably too computationally intensive way
%{
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
        for k = 1:length(allowable_nums)
            multiplier = allowable_nums(1) - allowable_nums(k) + 1;
            
            % FIX THIS THIS ISN'T RIGHT
            out_of_range = any(set_diff > goal_diff*multiplier + max_off | set_diff < goal_diff*multiplier - max_off);
        end
        
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
%}

end