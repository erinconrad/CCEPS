import scipy.io as sio
import seaborn as sns
import numpy as np
import statsmodels.formula.api as sm
from sklearn import preprocessing
import pandas as pd
from os.path import join as opj

basedir = '/Users/Eli/Dropbox/CNTProjects/CCEPs_Projects/CCEPS-main/'
parcellation = 'Brainnetome'

### load cceps networks

wave = 'N1'
fname = wave + '_GroupNetwork_' + parcellation + '.mat'
CCEP = sio.loadmat(opj(basedir,'results','parcellation',fname))
SC = sio.loadmat(opj(basedir,'results','parcellation',parcellation + 'SCFC.mat'))['SC']
FC = sio.loadmat(opj(basedir,'results','parcellation',parcellation + 'SCFC.mat'))['FC']

### compile variables into dataframe
N = CCEP['A'].shape[0] # get dimension of matrix/number of parcels
df = {'CCEP':CCEP['A'].reshape(N*N), 'SC':SC.reshape(N*N), 'FC':FC.reshape(N*N), \
	'D': CCEP['D'].reshape(N*N)**-1}
df = pd.DataFrame(df)

### perform OLS regression

result = sm.ols(formula="CCEP ~ SC + FC + D",data=df).fit()
print(result.summary())

### z score variables and perform regression

