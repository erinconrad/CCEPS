print('start')
import os
from os.path import join as opj
import numpy as np
import scipy.io as sio
import nibabel as nib
from scipy import stats
import matplotlib.pyplot as plt
import sys
from matplotlib.colors import ListedColormap

##############################
### Get brainmapping files ###
##############################

atlas = sys.argv[1]
resultsdir_fname = sys.argv[2]
homedir = "/Users/Eli"
basedir = "Dropbox/CNTProjects/CCEPs_Projects/CCEPS-main/"

# which scan to plot centroids from

os.environ['SUBJECTS_DIR']='/Applications/freesurfer/subjects'

sys.path.append(opj(homedir,basedir,'eli/visualize/ejcbrain/'))
import ejcbrain as EB

##################
### Set values ###
##################

savedir = opj(homedir,basedir,'results')
if not os.path.exists(savedir):
    os.makedirs(savedir)

#################
### Load data ###
#################

dfile = opj(homedir,basedir,"results/",resultsdir_fname)
data = sio.loadmat(dfile)
nodeData = data['nodeData']
ttls = [x[0][0] for x in data['plotTitles']] # process matlab cell containing plot titles
clim = data.get('clim',0.2) # get input for color axis limits -- otherwise use 0.2
if type(clim) == type(np.array([0])):
	clim = clim.flatten()[0]
cmin = data.get('cmin').flatten()[0]
cmax = data.get('cmax').flatten()[0]

###################
### Plot brains ###
###################

# use ejcbrain module to convert node data to vertex data for Schaefer, brainnetome, or lausanne

cmap = data.get('cmap',np.array('cividis')).flatten()[0]
print(cmap)
print(EB)
f = EB.surfplot_2x2xk(nodeData,atlas,ttls,savedir,clim_type=clim,cmin=cmin,cmax=cmax,cmap = cmap)
fname = resultsdir_fname.split('.')[0]+ ".png"
f.savefig(opj(savedir,fname),dpi=500,bbox_inches='tight',pad_inches=0)
