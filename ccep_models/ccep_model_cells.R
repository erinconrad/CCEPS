rm(list=ls())

basedir <- '/Users/Eli/Dropbox/CNTProjects/CCEPs_Projects/CCEPS-main-old/'
savedir <- paste0(basedir,'results/cceps_models/cells/')
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

# load cell maps
cell.maps <- read.csv(paste(basedir,'results','processed',paste0('CellMaps',parcellation,'.csv'),sep='/'),row.names = 1)

# expand cell maps to matrix form - rows should have cell vector b/c hypothesis is that it affects recording areas
N <- dim(FC)[1]
cell.maps.matrix <- lapply(cell.maps,function(cell) kronecker(matrix(1,N,1),t(matrix(cell,nrow = N,ncol = 1))))
cell.maps.vector <- lapply(cell.maps.matrix,as.vector)

for(wave in c('N1','N2')){
  results[[wave]] <- list()
  
  # load CCEPs networks
  fname <- paste0(wave,'_GroupNetwork_',parcellation,'.mat')
  CCEP <- readMat(paste(basedir,'results','parcellation',fname,sep='/'))
  
  # compile variables into dataframe
  df <- data.frame(CCEP=as.vector(CCEP$A),SC=as.vector(SC),FC=as.vector(FC),D=as.vector(CCEP$D)^-1)
  # add cell maps
  df <- cbind(df,as.data.frame(cell.maps.vector)) 
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
  results[[wave]]$full.model <- m
  
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

save(results,file = paste0(savedir,'BootstrapRegressionCellMaps_',parcellation,'.RData'))
