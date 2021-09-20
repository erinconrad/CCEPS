rm(list=ls())

basedir <- '/Users/Eli/Dropbox/CNTProjects/CCEPs_Projects/CCEPS-main/'
savedir <- paste0(basedir,'results/cceps_models/cells/')
dir.create(savedir,recursive = T)

source(paste0(basedir,'eli/miscfxns/packages.R'))
source(paste0(basedir,'eli/miscfxns/miscfxns.R'))
source(paste0(basedir,'eli/miscfxns/statfxns.R'))
source(paste0(basedir,'eli/plottingfxns/plottingfxns.R'))

parcellation <- 'Brainnetome'
nboot <- 10000

results <- list()
normalize <- 'RankINT'

# load FC and SC
SC <- readMat(paste(basedir,'results','parcellation',paste0(parcellation,'SCFC.mat'),sep='/'))$SC
FC <- readMat(paste(basedir,'results','parcellation',paste0(parcellation,'SCFC.mat'),sep='/'))$FC

# load cell maps
cell.maps <- read.csv(paste(basedir,'results','processed',paste0('CellMaps',parcellation,'.csv'),sep='/'),row.names = 1)

# expand cell maps to matrix form - rows should have cell vector b/c hypothesis is that it affects recording areas
N <- dim(FC)[1]
cell.maps.matrix <- lapply(cell.maps,function(cell) kronecker(matrix(1,N,1),t(matrix(cell,nrow = N,ncol = 1))))
cell.maps.vector <- lapply(cell.maps.matrix,as.vector)
cell.types <- names(cell.maps.matrix)
cell.types <- name(cell.types,cell.types)

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
  
  # define formula
  f <- formula(CCEP~SC+FC+D)
  
  # fit model on all data
  #df$CCEP <- log(df$CCEP)
  m <- lm.beta(lm(f,data=df))
  print(summary(m))
  
  results[[wave]]$full.model <- m
  #m$model$CCEPResid <- residuals(m)
  df[names(residuals(m)),'CCEPResid'] <- residuals(m)
  c.tests <- lapply(cell.types, function(cell)
                    cor.test(df$CCEPResid,df[,cell],use='pairwise.complete.obs',method='spearman'))
  results[[wave]]$cor$pvals <- sapply(c.tests,function(x) x$p.value)
  results[[wave]]$cor$r <- sapply(c.tests,function(x) unname(x$estimate))
  results[[wave]]$cor$scatter <- lapply(name(cell.types,cell.types), function(cell)
    na.omit(df[,c(cell,'CCEPResid')]))
   
  df <- inf.nan.mask(df)
  if(normalize == 'RankINT'){
    df <- rank_INT(df)
  }
  m.cells <- lapply(cell.types, function(cell) 
    lm.beta(lm(f=reformulate(response='CCEP',termlabels = c('FC','SC','D',cell),intercept = T),data=df)))
  results[[wave]]$lm$coefs <- sapply(m.cells,function(m) summary(m)$coef[-1,'Standardized'])
  results[[wave]]$lm$pvals <- sapply(m.cells,function(m) summary(m)$coef[-1,'Pr(>|t|)'])
  results[[wave]]$lm$scatter <- lapply(name(cell.types,cell.types), function(cell)
    na.omit(df[,c(cell,'CCEP')]))
  results[[wave]]$lm$scatter$FC <- na.omit(df[,c('FC','CCEP')])
}

# plot correlations
df.plt <- rbind(data.frame(cell=cell.types,r=results$N1$cor$r,p=results$N1$cor$pvals,wave='N1',stringsAsFactors = F),
                        data.frame(cell=cell.types,r=results$N2$cor$r,p=results$N2$cor$pvals,wave='N2',stringsAsFactors = F))
df.plt$p <- p.adjust(df.plt$p,method='fdr')
df.plt$p <- p.signif(df.plt$p)
df.plt$p[df.plt$p == 'ns']<- ''
p <- ggplot(df.plt) + geom_col(aes(x=cell,y=r,fill=wave),position='dodge') + 
  geom_text(data=df.plt[df.plt$wave=='N1',],aes(x=cell,y=max(df.plt$r*1.1),label=p)) +
  geom_text(data=df.plt[df.plt$wave=='N2',],aes(x=cell,y=min(df.plt$r*1.1),label=p)) +
  scale_fill_manual(values=wes_palettes$BottleRocket2,name='') + theme_bw() + standard_plot_addon() +
  xlab('') + theme(axis.text.x = element_text(angle=90,hjust=1,vjust=0.5))
ggsave(filename = paste0(savedir,'FCSCDResidual_CellTypeCorrelation',normalize,'.pdf'),plot = p,width = 18,height = 6,units = 'cm')

# plot relative effect sizes in linear model

idx <- nrow(results$N1$lm$coefs) # select coefficient for cells
df.plt <- rbind(data.frame(cell=cell.types,b=results$N1$lm$coefs[idx,],p=results$N1$lm$pvals[idx,],wave='N1',stringsAsFactors = F),
                data.frame(cell=cell.types,b=results$N2$lm$coefs[idx,],p=results$N2$lm$pvals[idx,],wave='N2',stringsAsFactors = F))
df.plt$p <- p.adjust(df.plt$p,method='fdr')
df.plt$p <- p.signif(df.plt$p)
df.plt$p[df.plt$p == 'ns']<- ''

# plot effect sizes of FC, SC, Distance
hl <- data.frame(N1=rowMeans(results$N1$lm$coefs[-idx,]),N2=rowMeans(results$N2$lm$coefs[-idx,]))
hl$var <- rownames(hl)
hl.plt <- collapse.columns(hl,cnames = c('N1','N2'),groupby = 'var')

p <- ggplot(df.plt) + geom_col(aes(x=cell,y=b,fill=wave),position='dodge') + 
  #geom_hline(aes(yintercept=values,color=names),data=hl.plt) + scale_color_manual(values=wes_palettes$BottleRocket2,name='')+
  #geom_text(aes(x=cell.types[1],y=values,color=names,label=group),data=hl.plt)+
  geom_text(data=df.plt[df.plt$wave=='N1',],aes(x=cell,y=max(df.plt$b*1.1),label=p)) +
  geom_text(data=df.plt[df.plt$wave=='N2',],aes(x=cell,y=min(df.plt$b*1.1),label=p)) +
  scale_fill_manual(values=wes_palettes$BottleRocket2,name='') + theme_bw() + standard_plot_addon() +
  xlab('') + theme(axis.text.x = element_text(angle=90,hjust=1,vjust=0.5))
ggsave(filename = paste0(savedir,'FCSCD_CellTypeRegression',normalize,'.pdf'),plot = p,width = 18,height = 6,units = 'cm')

# scatter plot biggest effects to see if relationship is real or outlier driven

plot(rank_INT(results$N2$cor$scatter$In1c))
plot(rank_INT(results$N2$lm$scatter$FC))

