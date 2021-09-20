rm(list=ls())

basedir <- '/Users/Eli/Dropbox/CNTProjects/CCEPs_Projects/CCEPS-main/'
savedir <- paste0(basedir,'results/cceps_models/')
dir.create(savedir,recursive = T)

source(paste0(basedir,'eli/miscfxns/packages.R'))
source(paste0(basedir,'eli/miscfxns/miscfxns.R'))
source(paste0(basedir,'eli/plottingfxns/plottingfxns.R'))

parcellation <- 'Brainnetome'
nboot <- 10000

results <- list()
normalize <- 'RankINT'
for(wave in c('N1','N2')){
  results[[wave]] <- list()
  
  # load CCEPs networks
  fname <- paste0(wave,'_GroupNetwork_',parcellation,'.mat')
  CCEP <- readMat(paste(basedir,'results','parcellation',fname,sep='/'))
  SC <- readMat(paste(basedir,'results','parcellation',paste0(parcellation,'SCFC.mat'),sep='/'))$SC
  FC <- readMat(paste(basedir,'results','parcellation',paste0(parcellation,'SCFC.mat'),sep='/'))$FC
  
  if(wave == 'N1'){
    p1 <- imagesc(SC) + theme(axis.text = element_blank(),axis.ticks=element_blank()) + nice_cbar() + coord_equal()
    p2 <- imagesc(FC) + theme(axis.text = element_blank(),axis.ticks=element_blank()) + nice_cbar() + coord_equal()
    p.all <- plot_grid(plotlist = list(p1,p2),align='hv',nrow=1)
    ggsave(filename = paste0(savedir,'SCFC.pdf'),plot = p.all,width = 18,height = 9,units = 'cm')
  }
  # compile variables into dataframe
  df <- data.frame(CCEP=as.vector(CCEP$A),SC=as.vector(SC),FC=as.vector(FC),D=as.vector(CCEP$D)^-1)
  df[df==Inf] <- NaN
  
  # plot correlation between variables
  r <- cor(df,use = 'pairwise.complete.obs')
  p <- imagesc(r,caxis_name = 'r',clim = c(0,1),cmap = 'Blues',overlay = round(r,2),overlay.text.col = 'white') + coord_equal()
  ggsave(filename = paste0(savedir,wave,'_VariableCorrelations.pdf'),plot = p,width = 8,height = 6,units = 'cm')
  
  # define formula
  f <- formula(CCEP~SC+FC+D)
  
  # fit model on all data
  m <- lm.beta(lm(f,data=df))
  print(summary(m))
  
  # plot distributions of variables
  df.plt <- collapse.columns(df)
  df.plt$names[df.plt$names == 'CCEP'] <- wave # rename after wave
  df.plt$names <- factor(df.plt$names,levels = c(wave,setdiff(unique(df.plt$names),wave))) # make N1/N2 come first
  p <- ggplot(df.plt) + geom_histogram(aes(x=values),fill='light blue') + facet_wrap(~names,scales = 'free',nrow=1) + theme_bw() +
    xlab('') + ylab('') + standard_plot_addon()
  ggsave(filename = paste0(savedir,wave,'_InputVariableDistributions.pdf'),plot = p,width = 18,height = 6,units = 'cm')
  
  # bootstrap 
  df <- inf.nan.mask(df)
  if(normalize == 'RankINT'){
    df <- rank_INT(df)  
  }
  df.boot <- lapply(1:nboot, function(k) df[sample(1:nrow(df),replace=T),])
  m.boot <- lapply(df.boot, function(d) lm.beta(lm(f,data=d)))
  results[[wave]]$coef.boot <- do.call('rbind',lapply(m.boot, function(m) summary(m)$coef[-1,'Standardized']))
}

## compare bootstrapped model coefficients
boot.diff <- as.data.frame(results$N1$coef.boot-results$N2$coef.boot)
pvals <- sapply(boot.diff,function(x) pval.2tail.np(0,x))
coefs.combined <- rbind(data.frame(results$N1$coef.boot,wave='N1',stringsAsFactors = F),
      data.frame(results$N2$coef.boot,wave='N2'))

df.plt <- collapse.columns(coefs.combined,cnames = colnames(results$N1$coef),groupby = 'wave')

p <- ggplot(df.plt) + geom_boxplot(aes(x=names,y=values,fill=group)) + scale_fill_manual(values=wes_palettes$BottleRocket2,name='') +
  annotate(x=names(pvals),y=max(coefs.combined[,-ncol(coefs.combined)])+.1,label=paste('p =',pvals),geom='text',size=3)+
  theme_bw() + xlab('') + ylab('Standardized beta') + ggtitle('Bootstrapped Model Coefficients') + standard_plot_addon()
ggsave(filename = paste0(savedir,'BootstrappedModelCoefficientComparison',normalize,'.pdf'),plot = p,width = 9,height = 6,units = 'cm')
