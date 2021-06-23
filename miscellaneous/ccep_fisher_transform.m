function [z,z_score,pval] = ccep_fisher_transform(r,n)

z = atanh(r);
ste = sqrt(n-3);
z_score = z.*ste;
pval = 2*normcdf(-abs(z_score));


end