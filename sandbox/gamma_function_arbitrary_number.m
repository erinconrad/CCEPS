function vep_fit = gamma_function_arbitrary_number(time,p)

assert(mod(length(p),3)==0) % p must be divisible by 3
nfunctions = length(p)/3; % how many gamma functions

gamma = nan(nfunctions,length(time));

for ig = 1:nfunctions
    n = p((ig-1)*3+1);
    t = p((ig-1)*3+2)/n;
    a = p((ig-1)*3+3);
    c = 1/max((time.^n).*exp(-time./t));

    for i = 1:length(time)
        gamma(ig,i) = c*(time(i)^n)*exp(-time(i)/t);
    end
    gamma(ig,:) = a*gamma(ig,:)./max(gamma(ig,:));
end

vep_fit = sum(gamma,1);

end