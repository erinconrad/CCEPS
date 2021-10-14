function adj_out = wrap_or_unwrap_adjacency(adj_in)

% This takes a 3d adjacency matrix (not symmetric) of size nch x nch x z OR
% a 2d matrix of size (nch*nch x z) and turns it into the other size. z may
% be 1

%% Decide which of 4 situations
if ndims(adj_in) == 1
    % easy, assume 2d wrapped
    threed = 0;
    flat = 1;
elseif ndims(adj_in) == 2
    [m,n] = size(adj_in);
    
    if m == n
        % assume 2d unwrapped (I'm screwed if z happens to equal nch^2)
        threed = 0;
        flat = 0;
    else
        % assume 3d unwrapped
        threed = 1;
        flat = 1;
    end
elseif ndims(adj_in) == 3
    % easy, assume 3d unwrapped
    threed = 1;
    flat = 0;
else
    error('what');
end
   
%% Flatten if not flat; unwrap if flat
% different for each situation


if threed == 0 && flat == 1
    % it is 2d wrapped, unwrap to 2d
    
    y = length(adj_in);
    nchs = (sqrt(y));
    if nchs-floor(nchs) > 0.01, error('what'); end
    nchs = round(nchs);
    
    adj_out = zeros(nchs,nchs);
    count = 0;
    for i = 1:nchs
        for j = 1:nchs
            count = count + 1;
            adj_out(i,j) = adj_in(count);
        end
    end
    
    if count ~= length(adj_in)
        error('what\n');
    end
elseif threed == 1 && flat == 1
    % 3d but wrapped, unwrap to 3d
    y = size(adj_in,1);
    nchs = (sqrt(y));
    if nchs-floor(nchs) > 0.01, error('what'); end
    nchs = round(nchs);
    
    z = size(adj_in,2);
    adj_out = nan(nchs,nchs,z);
    for k = 1:z
        curr_adj = adj_in(:,k);
        
        curr_out = zeros(nchs,nchs);
        
        count = 0;
        for i = 1:nchs
            for j = 1:nchs
                count = count + 1;
                curr_out(i,j) = curr_adj(count);
            end
        end
        
        if count ~= length(curr_adj)
            error('what\n');
        end
        
        adj_out(:,:,k) = curr_out;

    end
    
elseif threed == 0 && flat == 0
    % 2d unwrapped, flatten
    nchs = size(adj_in,1);
    adj_out = nan(nchs*nchs,1);
    count = 0;
    for i = 1:nchs
        for j = 1:nchs
            count = count + 1;
            adj_out(count) = adj_in(i,j);
        end
    end
    
elseif threed == 1 && flat == 0
    % 3d unwrapped, flatten
    z = size(adj_in,3);
    nchs = size(adj_in,1);
    adj_out = nan(nchs*nchs,z);
    for k = 1:z
        curr_out = zeros(nchs*nchs,1);
        curr_in = adj_in(:,:,k);
        count = 0;
        
        for i = 1:nchs
            for j = 1:nchs
                count = count + 1;
                curr_out(count) = curr_in(i,j);
            end
            
        end
        adj_out(:,k) = curr_out;
    end
    
end
    

end