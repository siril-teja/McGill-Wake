# -*- coding: utf-8 -*-
"""
Created on Wed Sep 18 11:29:49 2024

@author: emmac
"""

# Import packages
import numpy as np     # Matrices
import numpy.matlib # Opening up math operations
import pandas as pd    # Dataframes
import scipy as sp     # Interpolation etc.
import scipy.interpolate    # Interpolation
import matplotlib.pyplot as plt   # Plotting
import matplotlib.cm as cm # For colormaps on plots
from scipy.spatial import ConvexHull
from concurrent.futures import ThreadPoolExecutor
from tqdm import tqdm
from matplotlib.path import Path
from mpl_toolkits.mplot3d import Axes3D

# Setup parameters
plt.rcParams['figure.dpi']=100
# In[]:
# 1) Import & Clean
# Choose data import folder
filepath = r'C:\Users\emmac\Documents\SBES\Brown Lab\McGill\Data from Testing\McGill\McGill Surrogate 1\013__AR Comp More\Data'
filename = r'\013__AR Comp More_McGill_Surrogate1_AR_comp_50-200_25step_1of1_1_Main_processed.xlsx'

Time = pd.read_excel(filepath+filename,sheet_name='Timing.Sync Trigger') # Time
AppliedLoad = pd.read_excel(filepath+filename,sheet_name='Kinetics.JCS.Control') # Force control applied forces & moments
AppliedDisp = pd.read_excel(filepath+filename,sheet_name='Kinematics.JCS.Control') # Disp control applied rotations & translations
MeasuredLoad = pd.read_excel(filepath+filename,sheet_name='State.JCS Load') # Disp control measured forces & torques
MeasuredDisp_JCS = pd.read_excel(filepath+filename,sheet_name='State.JCS')  # Force control JCS rotations & translations

# Rename data columns to remove spaces for ease of accessing data in dataframes
Time.rename(columns = {'Setpoint Time':'Time'}, inplace = True)
AppliedLoad.rename(columns = {'Posterior Shear - Control':'Posterior', 'Compression - Control':'Compression',
                             'Left Lateral Shear - Control':'Lateral',  'Left Lateral Bending Torque - Control': 'LB',
                              'Right Axial Rotation Torque - Control':'AR','Flexion Torque - Control':'FE'}, inplace = True)
AppliedDisp.rename(columns = {'Anterior Translation - Control':'Anterior', 'Superior Translation - Control':'Superior',
                             'Right Lateral Translation - Control':'Lateral',  'Right Lateral Bending Angle - Control': 'LB',
                              'Left Axial Rotation Angle - Control':'AR','Extension Angle - Control':'FE'}, inplace = True)
MeasuredLoad.rename(columns = {'JCS Load Posterior Shear':'Posterior', 'JCS Load Compression':'Compression',
                             'JCS Load Left Lateral Shear':'Lateral',  'JCS Load Left lateral Bending Torque': 'LB',
                              'JCS Load Right Axial Rotation Torque':'AR','JCS Load Flexion Torque':'FE'}, inplace = True)
MeasuredDisp_JCS.rename(columns = {'JCS_Anterior':'Anterior', 'JCS_Superior':'Superior',
                             'JCS_Lateral':'Lateral',  'JCS_Lateral Bending': 'LB',
                              'JCS_Axial Rotation':'AR','JCS_Extension':'FE'}, inplace = True)
# In[]:
# Converting to Correct Data Type
def convertoDF(load,disp,time,hybrid):
# load will be forces/torques and disp will be translations/rotations regardless of control method
# disp will depend on whether we want to assess whole spine or just FSU (eventually can make a loop to do all values)
    df = pd.DataFrame()
    if hybrid == 0: # Displacement control
        df['ant_trans'] = disp.Anterior
        df['sup_trans'] = disp.Superior
        df['lat_trans'] = disp.Lateral
        df['LB_rot'] = disp.LB
        df['AR_rot'] = disp.AR
        df['FE_rot'] = disp.FE
        df['pos_load'] = load.Posterior
        df['comp_load'] = load.Compression
        df['lat_load'] = load.Lateral
        df['LB_torq'] = load.LB
        df['AR_torq'] = load.AR
        df['FE_torq'] = load.FE
        df['Time'] = time.Time
    elif hybrid == 1: # Moment control
        df['ant_trans'] = disp.Anterior
        df['sup_trans'] = disp.Superior
        df['lat_trans'] = disp.Lateral
        df['LB_rot'] = disp.LB
        df['AR_rot'] = disp.AR
        df['FE_rot'] = disp.FE
        df['pos_load'] = load.Posterior
        df['comp_load'] = load.Compression
        df['lat_load'] = load.Lateral
        df['LB_torq'] = load.LB
        df['AR_torq'] = load.AR
        df['FE_torq'] = load.FE
        df['Time'] = time.Time
        #need an elif for mixed hybrid values, and for hybrid values that vary by parameter...
    return df

# In[]:
dfdata_AR = convertoDF(MeasuredLoad,AppliedDisp,Time,0)
dfdata_C = convertoDF(AppliedLoad,MeasuredDisp_JCS,Time,1)
# In[]:
# 2) Removing NANs
def removeNANS(d):
    value_to_remove = "#NV"
    df_data = d[~((d['LB_rot'] == value_to_remove) | (d['FE_rot'] == value_to_remove))] 
    return df_data

# In[]:
df_AR_clean = removeNANS(dfdata_AR)
df_C_clean = removeNANS(dfdata_C)
# In[]:
# 3) Filtering
from scipy.signal import sosfiltfilt, butter
tstep=df_AR_clean['Time'][len(df_AR_clean['Time'])-1]-df_AR_clean['Time'][0]
N=len(df_AR_clean['Time'])
Fs=N/tstep
Fc=0.09
poles=4

def signalfilt(load,disp,poles,Fs,Fc):
    sos=butter(poles,1.65*Fc,fs=Fs, output='sos')
    x = sosfiltfilt(sos,load)
    y = sosfiltfilt(sos,disp)
    return (x,y)

Sup_trans,Comp_load = signalfilt(df_C_clean['sup_trans'],df_C_clean['comp_load'],poles,Fs,Fc)
AR_rot,AR_torq = signalfilt(df_AR_clean['AR_rot'],df_AR_clean['AR_torq'],poles,Fs,Fc)

df_AR_comp = pd.DataFrame()
df_AR_comp['sup_trans']=Sup_trans
df_AR_comp['AR_rot']=AR_rot
df_AR_comp['comp_load']=Comp_load
df_AR_comp['AR_torq']=AR_torq

# In[]:
# Plotting sequence
stiff_vals=np.divide(np.diff(df_AR_comp['AR_torq']),np.diff(df_AR_comp['AR_rot']))

# Convert axial rotation to radians for plotting
theta = np.deg2rad(df_AR_comp['AR_rot'][:-1]*10)

# Create meshgrid for plotting
#theta, z = np.meshgrid(theta, df_AR_comp['comp_load'])
z = df_AR_comp['comp_load']

# The radial distance is the stiffness (R value)
#r = stiff_vals
r = df_AR_comp['AR_torq']

# Now convert polar to cartesian coordinates for 3D plotting
x = r * np.cos(theta)
y = r * np.sin(theta)
#x = np.cos(theta)
#y = np.sin(theta)

# Filtering out outliers
combined = pd.DataFrame()
combined['AR']=theta
combined['AR Load']=df_AR_comp['AR_torq']
combined['AR x']=x
combined['AR y']=y
combined['Comp Z']=z
combined['Stiff']=r
band=0.0001
AR_comp_filtered=combined[:-1][abs(np.diff(combined['AR']))>band]    

# Create 3D plot
fig = plt.figure()
ax = fig.add_subplot(111, projection='3d')
ax.scatter(AR_comp_filtered['AR x'],AR_comp_filtered['AR y'],AR_comp_filtered['Comp Z'])

# Plot the surface
#ax.plot_surface(x, y, z, cmap='viridis')

ax.set_xlabel('X (Axial Rotation)')
ax.set_ylabel('Y (Axial Rotation)')
ax.set_zlabel('Compression (Newtons)')

plt.show()
# In[]:
# Plot rot vs load
plt.figure(figsize=(6, 6))
ax = plt.subplot(111, projection='polar')
ax.scatter(AR_comp_filtered['AR'],abs(AR_comp_filtered['AR Load']))    

# Plot rot vs stiff
plt.figure(figsize=(6, 6))
ax = plt.subplot(111, projection='polar')
#ax.scatter(AR_comp_filtered['AR'],abs(AR_comp_filtered['Stiff']))    
ax.scatter(combined['AR'],abs(combined['Stiff']))    
ax.set_ylim(0,1.5)

# In[]:
# McGill data