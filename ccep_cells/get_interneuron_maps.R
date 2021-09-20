rm(list=ls())

basedir <- '/Users/Eli/Dropbox/CNTProjects/CCEPs_Projects/CCEPS-main/'
datadir <- '/Users/Eli/Dropbox/CNTProjects/CCEPs_Projects/'
savedir <- paste0(basedir,'results/processed/')
dir.create(savedir,recursive = T)

source(paste0(basedir,'eli/miscfxns/packages.R'))
source(paste0(basedir,'eli/miscfxns/miscfxns.R'))
source(paste0(basedir,'eli/plottingfxns/plottingfxns.R'))

parcellation <- 'Brainnetome'

gene <- readMat(paste0(datadir,'data/gene/ParcellatedGeneExpressionLRHemiBrainnetome.mat'))
gene$LeftHemiParcelExpression
gene.names <- as.vector(unlist(gene$gene.names))

# load cell types and their corresponding genes
df.cell <- read.csv(paste0(datadir,'data/gene/Lake18_celltypes.csv'),stringsAsFactors = F)
cell.types <- unique(df.cell$Cluster)
names(cell.types) <- cell.types

# iterate through cell type and extract gene list
cell.genes <- lapply(cell.types, function(cell) df.cell$Gene[df.cell$Cluster == cell])
# average left hemi gene expression over  genes for each cell type, at parcel level
cell.maps <- lapply(cell.genes, function(genes) rowMeans(gene$LeftHemiParcelExpression[,gene.names %in% genes]))
cell.maps <- as.data.frame(cell.maps)

# duplicate left and right hemisphere
cell.maps[seq(2,210,by=2),] <- cell.maps[seq(1,209,by=2),]

# save
write.csv(x=cell.maps,file = paste0(savedir,'CellMapsBrainnetome.csv'))
