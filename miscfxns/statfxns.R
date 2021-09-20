################
### p-values ###
################

p.signif <- function(p){
  # take p values and make asterisks
  #   ns: p > 0.05
  # *: p <= 0.05
  # **: p <= 0.01
  # ***: p <= 0.001
  # ****: p <= 0.000001
  p.new <- rep('',length(p))
  p.new[is.na(p)] <- ''
  p.new[p > 0.05] <- 'ns'
  p.new[p < 0.05 & p > 0.01] <- '*'
  p.new[p <= 0.01 & p > 0.001] <- '**'
  p.new[p <= 0.001 & p > 0.000001] <- '***'
  p.new[p <= 0.000001] <- '****'
  names(p.new) <- names(p)
  return(p.new)
  
}

p.signif.matrix <- function(p){
  # take matrix of p values and make asterisks
  #   ns: p > 0.05
  # *: p <= 0.05
  # **: p <= 0.01
  # ***: p <= 0.001
  # ****: p <= 0.000001
  p.new <- matrix(data = '',nrow = nrow(p),ncol=ncol(p))
  p.new[p > 0.05] <- 'ns'
  p.new[p < 0.05 & p > 0.01] <- '*'
  p.new[p <= 0.01 & p > 0.001] <- '**'
  p.new[p <= 0.001 & p > 0.000001] <- '***'
  p.new[p <= 0.000001] <- '****'
  return(p.new)
  
}

matrix.fdr.correct <- function(pvals){
 pvals.mat <- matrix(p.adjust(as.vector(as.matrix(pvals)), method='fdr'),ncol=ncol(pvals))
 colnames(pvals.mat) <- colnames(pvals)
 return(pvals.mat) 
}

list.vec.fdr.correct <- function(X){
  # for a list where each element is a vector of p-values
  # FDR correct over all p-values and return to list
  # correct
  p.fdr <- p.adjust(unlist(X),method='fdr')
  # get lengths --> cumulative indices
  X.ind <- cumsum(sapply(X,length))
  # initialize
  X.fdr <- list()
  X.names <- names(X)
  # start off list with first portion
  X.fdr[[X.names[1]]] <- p.fdr[1:X.ind[1]]
  # fill in list elements 2 to n
  for(i in 2:length(X.ind)){
    X.fdr[[X.names[i]]] <- p.fdr[(1+X.ind[i-1]):(X.ind[i])]
  }
  return(X.fdr)
}

list.fdr.correct <- function(X){
  # unlist a list, fdr correct over all values
  # relist the list in the same structure and return
  return(relist(flesh=p.adjust(unlist(X),method='fdr'),skeleton=X))
}
