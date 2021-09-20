rm(list=ls())

basedir <- '/Users/Eli/Dropbox/CNTProjects/CCEPs_Projects/CCEPS-main-old/'
savedir <- paste0(basedir,'results/cceps_models/cells/')
dir.create(savedir,recursive = T)

source(paste0(basedir,'eli/miscfxns/packages.R'))
source(paste0(basedir,'eli/miscfxns/miscfxns.R'))
source(paste0(basedir,'eli/plottingfxns/plottingfxns.R'))

parcellation <- 'Brainnetome'

load(file = paste0(savedir,'BootstrapRegressionCellMaps_',parcellation,'.RData'))

## test each model coefficient for significance

for(wave in c('N1','N2')){
  df.int <- rank_INT(results[[wave]]$full.model$model)
  results[[wave]]$full.model.INT <- lm.beta(lm(CCEP~.,data=df.int))
  #plot(results[[wave]]$m.int)
}

library(car)
vif(results$N1$full.model.INT) # vif is way too high

## compare bootstrapped model coefficients
boot.diff <- as.data.frame(results$N1$coef.boot-results$N2$coef.boot)
pvals <- sapply(boot.diff,function(x) pval.2tail.np(0,x))
coefs.combined <- rbind(data.frame(results$N1$coef.boot,wave='N1',stringsAsFactors = F),
                        data.frame(results$N2$coef.boot,wave='N2'))

df.plt <- collapse.columns(coefs.combined,cnames = colnames(results$N1$coef),groupby = 'wave')
df.plt$names <- factor(df.plt$names,levels = c(c('SC','FC','D'),setdiff(unique(df.plt$names),c('SC','FC','D')))) # make SC, FC,D come first

p <- ggplot(df.plt) + geom_boxplot(aes(x=names,y=values,fill=group),size=.1,outlier.size = .5,outlier.alpha = 0.5,outlier.stroke = 0) + scale_fill_manual(values=wes_palettes$BottleRocket2,name='') +
  annotate(x=names(pvals),y=max(coefs.combined[,-ncol(coefs.combined)])+.1,label=paste0(ifelse(pvals<0.05,yes='*',no='')),geom='text',size=2)+
  theme_bw() + xlab('') + ylab('Standardized beta') + ggtitle('Bootstrapped Model Coefficients') + standard_plot_addon() +
  theme(axis.text.x=element_text(angle=90,hjust=1))
ggsave(filename = paste0(savedir,'BootstrappedModelCoefficientComparison',normalize,'.pdf'),plot = p,width = 24,height = 6,units = 'cm')
