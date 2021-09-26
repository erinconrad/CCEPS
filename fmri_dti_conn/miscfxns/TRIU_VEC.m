function edges = TRIU_VEC(A)

% INPUTS:
% A: NxN matrix
% 
% OUTPUTS:
% edges: upper triangle edges in an N*(N-1)/2 vector

N=length(A);
edges = A(~~triu(ones(N)) & ~eye(N));