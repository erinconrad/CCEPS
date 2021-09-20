unit.test <- function(test,pass,fail){
	# test: logical expression to evaluate
	# pass: error to print if true
	# fail: error to print if false
	if(test){
		print(pass)
	} else{print(fail)}

}

fisher.r.to.z <- function(r){
  r <- 0.5*(log(1+r) - log(1-r))
  return(r)
}

colSD <- function(x){
  return(apply(x,2,sd))
}

fda <- function(x1,x2,nperms = 1000){
	# x1: N-by-P matrix where there are N observational units and P are features, probably time
	# x2: M-by-P matrix where there are N observational units and P are features, probably time
	# perform functional data analysis, where you compute the mean difference between column
	# means of x1 and x2 and compare them to permuted versions of x1 and x2 with the observational units
	# switched	


}

get.inf.nan.mask <- function(x){
	# INPUTS:
	# x: matrix, df, or vector
	# 
	# OUTPUTS:
	# mask: mask for x with all rows (if matrix or df) or elements (if vector) containing Infs or NaNs set to FALSE

	if(is.vector(x)){
		mask <- x %in% c(-Inf,Inf,NaN,NA)# find infs or nans
	} else if(is.matrix(x) | is.data.frame(x)){
		mask <- do.call('cbind',lapply(1:ncol(x),function(j) x[,j] %in% c(-Inf,Inf,NaN,NA))) # find infs or nans
	}
	return(mask)
}

inf.nan.mask <- function(x){
	# INPUTS:
	# x: matrix, df, or vector
	#
	# OUTPUTS:
	# x.masked: x with all rows (if matrix or df) or elements (if vector) containing Infs or NaNs removed
	
	if(is.vector(x)){
		mask <- x %in% c(-Inf,Inf,NaN,NA)# find infs or nans
		x.masked <- x[!mask]
	} else if(is.matrix(x) | is.data.frame(x)){
		mask <- do.call('cbind',lapply(1:ncol(x),function(j) x[,j] %in% c(-Inf,Inf,NaN,NA))) # find infs or nans
		x.masked <- x[rowSums(mask)==0,]
	}
	return(x.masked)
	
}

quiet <- function(x) { 
	# https://stackoverflow.com/questions/34208564/how-to-hide-or-disable-in-function-printed-message/34208658#34208658
  sink(tempfile()) 
  on.exit(sink()) 
  invisible(force(x)) 
} 

name <- function(x,x.names){
	# INPUTS:
	# x: vector or dataframe
	# x.names: names for elements or columns of x
	# OUTPUTS:
	# x with x.names as names
	names(x) <- x.names
	return(x)
}

collapse.columns <- function(df,cnames=colnames(df),groupby=NULL){
  # INPUTS:
  # df: dataframe
  # cnames: column names to perform operation on, default to all columns
  # groupby: column name to group variables by, treated separately from variables in cnames
  
  # OUTPUTS:
  # df.new: dataframe with 2 columns:
  # values: all columns in cnames vertically concatenated. 
  # names: elements of cnames corresponding to rows
  # group: groups of observations in df for each variable in cnames
  
  df.names <- do.call('cbind',lapply(cnames, function(n) rep(n,nrow(as.matrix(df[,cnames])))))  
  df.new <- data.frame(values = as.vector(as.matrix(df[,cnames])),names=as.vector(df.names),stringsAsFactors=F)
  if(!is.null(groupby)){
    df.grp <- do.call('cbind',lapply(cnames,function(n) df[,groupby]))
    df.new$group <- as.vector(df.grp)
  }
  return(df.new)
}

col.Which.Max <- function(x){
  cwm <- unlist(apply(x,2,function(y) which.max(y)))
  return(cwm)
}

row.Which.Max <- function(x){
  rwm <- unlist(apply(x,1,function(y) which.max(y)))
  return(rwm)
}

pval.np.pub <- function(p,n){
	# INPUTS:
	# p: matrix or vector of p values from non-parametric test
	# n: number of permutations from test
	#
	# OUTPUTS:
	# p.new: matrix or vector of p values with p = 0 reworded to p < 1/n

	p.new <- p
	p.new[p == 0] <- paste('p <',1/n)
	return(p.new)
}
pval.2tail.np <- function(test.val,dist){
  # test.val: individual value being compared to distribution
  # dist: vector,distribution of values under some null model, or otherwise
  # sig.fig: number of significant figures
  # compute 2-tailed p-value for test value occurring in distribution
  dist <- as.numeric(dist)
  pval.2tail <- 2*min(mean(test.val >= dist),mean(test.val <= dist))
  return(pval.2tail)
}

getGroupColors <- function(grps=NULL){
	# INPUTS:
	# vector of group names
	return(setNames(c('#047391','#FF7F00'),grps))
}

list.posthoc.correct <- function(X,method){
  # unlist a list, posthoc correct over all values according to "method"
  # relist the list in the same structure and return
  return(relist(flesh=p.adjust(unlist(X),method=method),skeleton=X))
}

outlier.mask <- function(x){
  # return mask of values in x that are outliers
  return(x %in% boxplot.stats(x)$out)
}


rank_INT_base <- function(x,k=3/8){
  mask <- x %in% c(-Inf,Inf,NaN,NA)
  x[!mask] <- qnorm((rank(x[!mask])-k)/(length(x[!mask]) - 2*k + 1))
  return(x)
}

rank_INT <- function(x,k=3/8){
	# INPUTS:
	# x: any R object
	# OUTPUTS:
	# that object normalized using rank inverse normal transformation
	# elementwise if list
	# columnwise if matrix or data frame

	if(is.list(x) & !is.data.frame(x)){
		return(lapply(x,rank_INT))
	} else if(is.matrix(x)){
		x.names <- name(colnames(x),colnames(x))
		if(is.null(x.names)){x.names <- 1:ncol(x)}
		x.int <- sapply(x.names, function(j) rank_INT_base(x[,j]))
		rownames(x.int) <- rownames(x)
		return(x.int)
	} else if(is.vector(x)){
		return(rank_INT_base(x))
	} else if(is.data.frame(x)){
		x.int <- as.data.frame(sapply(name(names(x),names(x)), function(j) rank_INT_base(x[,j])))
		rownames(x.int) <- rownames(x)
		return(x.int)
	}
}