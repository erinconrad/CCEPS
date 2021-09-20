rm(list=ls())

basedir <- '/Users/Eli/Dropbox/CNTProjects/CCEPs_Projects/CCEPS-main/'
datadir <- '/Users/Eli/Dropbox/CNTProjects/CCEPs_Projects/'
savedir <- paste0(basedir,'results/cceps_models/thalamus/')
dir.create(savedir,recursive = T)

source(paste0(basedir,'eli/miscfxns/packages.R'))
source(paste0(basedir,'eli/miscfxns/miscfxns.R'))
source(paste0(basedir,'eli/plottingfxns/plottingfxns.R'))

parcellation <- 'Brainnetome'
nboot <- 10000

results <- list()
normalize <- ''

# load FC and SC
SC <- readMat(paste(basedir,'results','parcellation',paste0(parcellation,'SCFC.mat'),sep='/'))$SC
FC <- readMat(paste(basedir,'results','parcellation',paste0(parcellation,'SCFC.mat'),sep='/'))$FC

# get thalamic connectivity

roi.names <- read.table(file = paste0(datadir,'data/nifti/BN_Atlas_246_LUT.txt'),header=1)
thal.idx <- grep('tha',roi.names$Unknown)
names(thal.idx) <- roi.names$Unknown[thal.idx]
thal.conn <- as.data.frame(lapply(thal.idx, function(idx) SC[idx,]))

# expand thalamus connectivity to matrix form - rows should have cell vector b/c hypothesis is that it affects recording areas
N <- dim(FC)[1]
thal.conn.matrix <- lapply(thal.conn,function(roi) kronecker(matrix(1,N,1),t(matrix(roi,nrow = N,ncol = 1))))
thal.conn.vector <- lapply(thal.conn.matrix,as.vector)

for(wave in c('N1','N2')){
  results[[wave]] <- list()
  
  # load CCEPs networks
  fname <- paste0(wave,'_GroupNetwork_',parcellation,'.mat')
  CCEP <- readMat(paste(basedir,'results','parcellation',fname,sep='/'))
  
  # compile variables into dataframe
  df <- data.frame(CCEP=as.vector(CCEP$A),SC=as.vector(SC),FC=as.vector(FC),D=as.vector(CCEP$D)^-1)
  # add cell maps
  df <- cbind(df,as.data.frame(thal.conn.vector)) 
  # exclude the empty entries of distance matrix
  df[df==Inf] <- NaN
  
  # plot correlation between variables
  r <- cor(df,use = 'pairwise.complete.obs')
  p <- imagesc(r,caxis_name = 'r',clim = c(0,1),cmap = 'Blues',overlay = round(r,2),overlay.text.col = 'white') + coord_equal() +
    theme(axis.text.x = element_text(angle =90,hjust = 1))
  ggsave(filename = paste0(savedir,wave,'_VariableCorrelations.pdf'),plot = p,width = 18,height = 18,units = 'cm')
  
  # define formula
  f <- formula(CCEP~.)
  
  # fit model on all data
  m <- lm.beta(lm(f,data=df))
  print(summary(m))
  
  # bootstrap 
  df <- inf.nan.mask(df)
  if(normalize == 'RankINT'){
    df <- rank_INT(df)  
  }
  
  df.boot <- lapply(1:nboot, function(k) df[sample(1:nrow(df),replace=T),])
  m.boot <- list()
  for(boot in 1:nboot){
    if(boot/1000 == round(boot/1000)){
      print(paste('Bootstrap',boot))
    }
    m.boot[[boot]] <- lm.beta(lm(f,data=df.boot[[boot]]))
  }
  #m.boot <- lapply(df.boot, function(d) lm.beta(lm(f,data=d)))
  results[[wave]]$coef.boot <- do.call('rbind',lapply(m.boot, function(m) summary(m)$coef[-1,'Standardized']))
}

## compare bootstrapped model coefficients
boot.diff <- as.data.frame(results$N1$coef.boot-results$N2$coef.boot)
pvals <- sapply(boot.diff,function(x) pval.2tail.np(0,x))
coefs.combined <- rbind(data.frame(results$N1$coef.boot,wave='N1',stringsAsFactors = F),
                        data.frame(results$N2$coef.boot,wave='N2'))

df.plt <- collapse.columns(coefs.combined,cnames = colnames(results$N1$coef),groupby = 'wave')
df.plt$names <- factor(df.plt$names,levels = c(c('SC','FC','D'),setdiff(unique(df.plt$names),c('SC','FC','D')))) # make SC, FC,D come first

p <- ggplot(df.plt) + geom_boxplot(aes(x=names,y=values,fill=group)) + scale_fill_manual(values=wes_palettes$BottleRocket2,name='') +
  annotate(x=names(pvals),y=max(coefs.combined[,-ncol(coefs.combined)])+.1,label=paste0(ifelse(pvals<0.05,yes='*',no='')),geom='text',size=2)+
  theme_bw() + xlab('') + ylab('Standardized beta') + ggtitle('Bootstrapped Model Coefficients') + standard_plot_addon() +
  theme(axis.text.x=element_text(angle=90,hjust=1))
ggsave(filename = paste0(savedir,'BootstrappedModelCoefficientComparison',normalize,'.pdf'),plot = p,width = 24,height = 6,units = 'cm')
