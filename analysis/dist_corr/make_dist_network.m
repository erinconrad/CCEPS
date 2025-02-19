function A = make_dist_network(locs)

nchs = size(locs,1);

A = nan(nchs,nchs);
for i = 1:nchs
    for j = 1:i-1
        %dist = vecnorm(locs(i,:)-locs(j,:));
        dist = sqrt((locs(i,1)-locs(j,1)).^2+...
            (locs(i,2)-locs(j,2)).^2+...
            (locs(i,3)-locs(j,3)).^2);
        metric = dist;
        A(i,j) = metric;
        A(j,i) = metric;
    end
end

end