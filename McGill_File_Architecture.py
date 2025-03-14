# -*- coding: utf-8 -*-
"""
Created on Wed Dec 11 15:25:29 2024

@author: ecoltoff
"""

import os
import pandas as pd
import numpy as np     # Matrices
import scipy as sp     # Interpolation etc.
import scipy.interpolate    # Interpolation
import chardet
import matplotlib
import matplotlib.pyplot as plt   # Plotting
from pathlib import Path

# In[]:
# Polar Functions
def cart2pol(x, y):
    rho = np.sqrt(x**2 + y**2)
    phi = np.arctan2(y, x)
    phi = np.where(phi<0,2*np.pi+phi,phi)
    return(rho, phi)

def pol2cart(rho, phi):
    x = rho * np.cos(phi)
    y = rho * np.sin(phi)
    return(x, y)

def cart2pol_vel(x,y):
    [r,t]=cart2pol(x,y)
    dr=np.diff(r)
    dt=np.diff(t)
    return r,t,dr,dt

# Plotting in Polar
def polarplot(t,r,c,s): # add in optional lim variable?
    fig, ax = plt.subplots(subplot_kw={'projection': 'polar'})
    ax.scatter(t,r,c=c,s=s) #[0:lim]
    plt.show()
    
# In[]:
# McGill tests file setup
# Define the list of folders and the parent directory for the specimens
#pre_filename = r'X:\01_people\Coltoff\Brown Lab Files\Dissertation Data\McGill-Wakeforest Testing'
pre_filename = r'C:\Users\emmac\Documents\SBES\Brown Lab\McGill\Data from Testing\McGill\McGill-Wakeforest Testing'
folders = ['0-180', '105-285', '120-300', '135-315', '15-195',
           '150-330', '165-345', '30-210', '45-225', '60-240', '75-255', '90-270']
ray_vals = ['0','180','105','285','120','300','135','315','15','195','150','330','165','345','30','210','45','225','60','240','75','255','90','270']
folder_theta_vals = []
theta_options = []
for folder in folders:
    start, end = folder.split('-') 
    start = int(start)
    end = int(end)
    folder_theta_vals.append([folder, start, end])
    theta_options.append(start)
    theta_options.append(end)
# In[]:
# Plot individual test behaviors from McGill

# Replace with actual specimen directory names
specimen_dirs = ['McGill Spec 1', 'McGill Spec 2', 'McGill Spec 3', 'Sawbones']

# Initialize a dictionary to hold the data for each specimen
specimen_data_MG = {specimen: pd.DataFrame() for specimen in specimen_dirs}

# Initialize an empty dictionary to store the data
MG_data_summary = {}  # First column for Ray values
#ray_vals_MG=[]
    
# Loop through each specimen and process the folders
for specimen in specimen_dirs:
    all_data = []  # List to hold data for the current specimen
    MG_data_summary[specimen] = []
    for folder in folders:
        # Define the path to the Test1.Stop file
        file_path = os.path.join(
            pre_filename, specimen, folder, folder, "Test1")#, "Test1.Stop.csv")
        file_path_w_file = os.path.join(file_path,"Test1.Stop.csv")
        if os.path.exists(file_path_w_file):  # Check if the file exists
            # Read the file into a dataframe, assuming it's a CSV or tab-delimited file
            # Adjust delimiter and column names if necessary
            # Change delimiter if needed
            with open(file_path_w_file, 'rb') as f:
                result = chardet.detect(f.read())
                #print(result)
            df = pd.read_csv(file_path_w_file, encoding=result["encoding"])#,delimiter="\t")
            # Extract the required columns and add a column for the folder name
            extracted_data = df[['Total Time (s)', 'Rotation(Rotary:Rotation) (deg)','Torque(Rotary:Torque) (N·m)']].copy()
            extracted_data['Rotation(Rotary:Rotation) (deg)']=extracted_data['Rotation(Rotary:Rotation) (deg)']-extracted_data['Rotation(Rotary:Rotation) (deg)'][0]
            #df.rename(columns={"A": "a", "B": "c"})
            extracted_data['Folder'] = folder
            start, end = folder.split('-') 
            start = int(start)
            end = int(end)
            extracted_data['Theta'] = np.where(extracted_data['Rotation(Rotary:Rotation) (deg)'] >= 0, start, end)
            #    extracted_data['DT']=np.append(np.diff(), 0) # probably don't need because DT should be basically zero, could help with NZ tho
            extracted_data['Test Torque'] = np.where((extracted_data['Theta'] >= 180) & (extracted_data['Theta'] <= 270), abs(extracted_data['Torque(Rotary:Torque) (N·m)']), -abs(extracted_data['Torque(Rotary:Torque) (N·m)']))
            extracted_data['Test Torque'] = np.where((extracted_data['Theta'] >= 0) & (extracted_data['Theta'] <= 90), abs(extracted_data['Torque(Rotary:Torque) (N·m)']), -abs(extracted_data['Torque(Rotary:Torque) (N·m)']))
            extracted_data['DR']=np.append(np.diff(extracted_data['Test Torque']), 0) 
            #90 <= extracted_data['Theta'] >= 0
            #extracted_data['tf'] = np.where(extracted_data['Rotation(Rotary:Rotation) (deg)'] >= 0, 1, 0) 
            all_data.append(extracted_data)
            
            #ray_vals_MG.append(start)
            MG_data_summary[specimen].append(max(extracted_data.loc[extracted_data['Theta'] == start, 'Test Torque']))
            #ray_vals_MG.append(end)
            MG_data_summary[specimen].append(min(extracted_data.loc[extracted_data['Theta'] == end, 'Test Torque']))
            
            # Plotting the data:
            fig=plt.figure()
            plt.scatter(df['Torque(Rotary:Torque) (N·m)'],extracted_data['Rotation(Rotary:Rotation) (deg)'])
            plt.xlabel('Torque (Nm)')
            plt.ylabel('Rotation (deg)')
            plt.title(f'Torque vs Displacement Curve for {specimen} {folder}')
            plt.savefig(os.path.join(r'C:\Users\emmac\Documents\SBES\Brown Lab\McGill\Processing Files\Figures', f'{specimen}_{folder}.png'))
            plt.close()
            
    # Combine all data for the specimen into a single dataframe
    specimen_data_MG[specimen] = pd.concat(all_data, ignore_index=True)

# Now specimen_data contains a dataframe for each specimen
# You can access each dataframe using specimen_data['Specimen1'], specimen_data['Specimen2'], etc.

# Example: Save each dataframe to a CSV file
for specimen, data in specimen_data_MG.items():
    output_file = f"{specimen}_data.csv"
    data.to_csv(output_file, index=False)
    print(f"Saved data for {specimen} to {output_file}")
    
# Convert dictionary to Pandas DataFrame
MG_dat_sum = pd.DataFrame(MG_data_summary,index=ray_vals)

# Save as Excel or CSV
MG_dat_sum.to_excel(f"{specimen}_summary_MG.xlsx", index=False)  # Save as an Excel file
MG_dat_sum.to_csv(f"{specimen}_summary_MG.csv", index=False)  # Save as a CSV file


# In[]:
# To turn tests into XY grid
for specimen in specimen_dirs:
    polarplot(np.radians(specimen_data_MG[specimen]['Theta'].values),abs(specimen_data_MG[specimen]['Rotation(Rotary:Rotation) (deg)'].values),'black',10)
    
    specimen_data_MG[specimen]['X'],specimen_data_MG[specimen]['Y']=pol2cart(specimen_data_MG[specimen]['Rotation(Rotary:Rotation) (deg)'].values, specimen_data_MG[specimen]['Theta'].values)
# =============================================================================
#     fig = plt.figure()
#     plt.scatter(specimen_data_MG[specimen]['X'], specimen_data_MG[specimen]['Y'])
#     plt.xlabel('Lateral Bending Bending (deg)')
#     plt.ylabel('Flexion Extension Bending (deg)')
#     plt.title(f'{specimen}')
# =============================================================================
    
# =============================================================================
#     fig=plt.figure()
#     ax=fig.add_subplot(projection='3d')
# #    ax.scatter(specimen_data[specimen]['X'], specimen_data[specimen]['Y'], specimen_data[specimen]['Torque(Rotary:Torque) (N·m)'])
#     ax.scatter(specimen_data_MG[specimen]['X'], specimen_data_MG[specimen]['Y'], specimen_data_MG[specimen]['Test Torque'])
#     ax.set_title(f'{specimen}')
#     ax.set_xlabel('Lateral Bending Bending (deg)')
#     ax.set_ylabel('Flexion Extension Bending (deg)')
#     ax.set_zlabel('Resultant Moment (Nm)')
# 
# =============================================================================
# In[]:
# Surface plotting functions
def surf_gen(df):
    output  = sp.interpolate.bisplrep(df['X'],df['Y'],df['Torque(Rotary:Torque) (N·m)'], full_output=1, kx=4, ky=4) #Fits a bspline curve to surface
    tck = output[0] #Used later for evaluating the surface at specific points
    grid_resolution = 1000
    # Test non-polar meshgrid definition
    xt = np.linspace(np.ceil(np.min(df['X'])), np.ceil(np.max(df['X'])), grid_resolution)
    yt = np.linspace(np.ceil(np.min(df['Y'])), np.ceil(np.max(df['Y'])), grid_resolution)
    xv, yv = np.meshgrid(xt, yt)

    zv = np.array([[sp.interpolate.bisplev(x,y,tck) for (x,y) in zip(x_list,y_list)] for (x_list,y_list) in zip(xv,yv)]) 

    Z = zv
    Z = (Z-Z.min())/(Z.max()-Z.min())

    tick_max=np.ceil(np.max(zv)) # for figure scaling, based on max expected stiffness
    return xv,yv,zv
# In[]:
# Plot slice behaviors from Wake Forest - functions
# Get all test files in folder
def get_xlsx_files(folder_path):
    xlsx_files = [os.path.join(folder_path, file) for file in os.listdir(folder_path) if file.endswith('.xlsx')]
    return xlsx_files

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

def removeNANS(d):
    value_to_remove = "#NV"
    df_data = d[~((d['LB_rot'] == value_to_remove) | (d['FE_rot'] == value_to_remove))] 
    return df_data

def theta_round(rounding_values, values_to_round):
    # Function to round each value to the nearest in the predetermined list
    rounded_values = [
        min(rounding_values, key=lambda x: abs(x - value)) for value in values_to_round
    ]    
    return rounded_values  
    
def stiffness(D):
    disps=np.concatenate([np.array(D['LB_rot'])[:,np.newaxis],np.array(D['FE_rot'])[:,np.newaxis]],axis=1)
    FR=np.sqrt(np.sum(disps**2,axis=1)) # resultant ROM
    FR_sign=np.multiply(FR,np.sign(D['FE_rot']))
    dDLB=np.diff(D['LB_rot'])[:,np.newaxis]#.T
    dDFE=np.diff(D['FE_rot'])[:,np.newaxis]#.T
    dD=np.concatenate([dDLB,dDFE],axis=1)
    
    loads=np.concatenate([np.array(D['LB_torq'])[:,np.newaxis],np.array(D['FE_torq'])[:,np.newaxis]],axis=1)
    FL=np.sqrt(np.sum(loads**2,axis=1)) # resultant ROM
    FL_sign=np.multiply(FL,np.sign(D['LB_rot']))
    #FL_sign=np.multiply(FL,np.sign(D['FE_rot'])*np.sign(D['LB_rot']))
    dFLB=np.diff(D['LB_torq'])[:,np.newaxis]#.T
    dFFE=np.diff(D['FE_torq'])[:,np.newaxis]#.T
    dF=np.concatenate([dFLB,dFFE],axis=1)
    
    dFdD=np.concatenate([np.divide(dFLB,dDLB),np.divide(dFFE,dDFE)],axis=1)
    dFdD_rot=np.sqrt(np.sum(dFdD**2,axis=1))
    return FR, FR_sign, FL, dD, dF, dFdD, dFdD_rot, FL_sign

# In[]:
# Plotting slice behaviors from Wake Forest - implementation

# Choose data import folder
filepath = r'C:\Users\emmac\Documents\SBES\Brown Lab\McGill\Data from Testing\McGill\FE-LB Trajectories' #Home Working Folder
xlsx_files_list = get_xlsx_files(filepath)
#print(xlsx_files_list)

# Dictionary to hold DataFrames
dataframes_dict = {}

# Iterate over file names
for file_name in xlsx_files_list:
    df_name = file_name.split('.')[0]
    df_name = df_name.split('\\')[-1]
    df_name = file_name.split(df_name)[0] + df_name
    # Add DataFrame to the dictionary
    dataframes_dict[df_name] = file_name


specimen_data_WF = {specimen: pd.DataFrame() for specimen in specimen_dirs}

# Initialize an empty dictionary to store the data
WF_data_summary = {}  # First column for Ray values

# Create a DataFrame of DataFrames
#all_dataframe = pd.DataFrame() #pd.DataFrame.from_dict(dataframes_dict, orient='index')

for filename in xlsx_files_list:
    print(filename)
    
    # Specimen details
    specimen_dirs = ['McGill Spec 1', 'McGill Spec 2', 'McGill Spec 3', 'Sawbones']  # Names for the final dataframe
    specimen_str = ['McGill_Surrogate1', 'McGill_Surrogate2', 'McGill_Surrogate3', 'Sawbones']  # Substrings to match in filenames

    for i, specimen in enumerate(specimen_str): #may need to change it back to specimen_str
        if specimen in filename:  # Check if the substring is in the filename
            curr_specimen = specimen_dirs[i]  # Map to the corresponding specimen directory name
            all_data = []  # List to hold data for the current specimen
            break  # Break after finding the first match
    
    WF_data_summary[specimen] = []
    
    hybrid = 0 # 0 = Displacement control, 1 = Force control
    Time = pd.read_excel(filename,sheet_name='Timing.Sync Trigger') # Time
    #AppliedLoad = pd.read_excel(filename,sheet_name='Kinetics.JCS.Control') # Force control applied forces & moments
    AppliedDisp = pd.read_excel(filename,sheet_name='Kinematics.JCS.Control') # Disp control applied rotations & translations
    MeasuredLoad = pd.read_excel(filename,sheet_name='State.JCS Load') # Disp control measured forces & torques
    MeasuredDisp_JCS = pd.read_excel(filename,sheet_name='State.JCS')  # Force control JCS rotations & translations
    
    # Rename data columns to remove spaces for ease of accessing data in dataframes
    Time.rename(columns = {'Setpoint Time':'Time'}, inplace = True)
    #AppliedLoad.rename(columns = {'Posterior Shear - Control':'Posterior', 'Compression - Control':'Compression',
    #                             'Left Lateral Shear - Control':'Lateral',  'Left Lateral Bending Torque - Control': 'LB',
    #                              'Right Axial Rotation Torque - Control':'AR','Flexion Torque - Control':'FE'}, inplace = True)
    AppliedDisp.rename(columns = {'Anterior Translation - Control':'Anterior', 'Superior Translation - Control':'Superior',
                                 'Right Lateral Translation - Control':'Lateral',  'Right Lateral Bending Angle - Control': 'LB',
                                  'Left Axial Rotation Angle - Control':'AR','Extension Angle - Control':'FE'}, inplace = True)
    MeasuredLoad.rename(columns = {'JCS Load Posterior Shear':'Posterior', 'JCS Load Compression':'Compression',
                                 'JCS Load Left Lateral Shear':'Lateral',  'JCS Load Left lateral Bending Torque': 'LB',
                                  'JCS Load Right Axial Rotation Torque':'AR','JCS Load Flexion Torque':'FE'}, inplace = True)
    MeasuredDisp_JCS.rename(columns = {'JCS_Anterior':'Anterior', 'JCS_Superior':'Superior',
                                 'JCS_Lateral':'Lateral',  'JCS_Lateral Bending': 'LB',
                                  'JCS_Axial Rotation':'AR','JCS_Extension':'FE'}, inplace = True)

    #dfdata = convertoDF(MeasuredLoad,AppliedDisp,Time,0)
    dfdata = convertoDF(MeasuredLoad,MeasuredDisp_JCS,Time,0)
    dfclean = removeNANS(dfdata)
#    [path_r,path_t,path_dr,path_dt]=cart2pol_vel(dfclean['LB_rot'].to_numpy().astype(float),dfclean['FE_rot'].to_numpy().astype(float))
    [path_r,path_t,path_dr,path_dt]=cart2pol_vel(dfclean['FE_rot'].to_numpy().astype(float),dfclean['LB_rot'].to_numpy().astype(float))
    dffull=dfclean
    [FR, FR_sign, FL, dD, dF, dFdD, dFdD_rot, FL_sign]=stiffness(dffull)
    
    extracted_data=pd.DataFrame()
    extracted_data['Theta-path-rad']=path_t
#    extracted_data['DT']=np.append(path_dt, 0) # probably don't need because DT should be basically zero, could help with NZ tho
    extracted_data['Rho-path']=path_r
    extracted_data['DR']=np.append(path_dr, 0)
    extracted_data['Rotation']=FR
    extracted_data['Load']=FL
    specimen_theta_vals=theta_round([x for x in theta_options if isinstance(x, int)], np.degrees(path_t))
#    specimen_theta_vals=theta_round(np.array([float(value) for row in folder_theta_vals for value in (row[1], row[2])]).reshape(-1, 1),np.degrees(path_t))
    extracted_data['Theta']=specimen_theta_vals
    extracted_data['Folder'] = 0 
         
    for item in folder_theta_vals:
        # Create a mask for rows in specimen_theta_vals that match item[1] or item[2]
#        mask_low = [val == item[1] for val in specimen_theta_vals] 
#        mask_high = [val == item[2] for val in specimen_theta_vals] 
        tol_deg=2
        tol = np.radians(tol_deg)
        mask_low = [(item[1] - tol <= val <= item[1] + tol) for val in specimen_theta_vals]
        mask_high = [(item[2] - tol <= val <= item[2] + tol) for val in specimen_theta_vals]
        # Check if the mask matches any rows
        if any(mask_low):  # Correct way to check for at least one match
           matching_indices_low = [i for i, is_match in enumerate(mask_low) if is_match]
           extracted_data.loc[matching_indices_low, 'Folder'] = item[0]
           extracted_data.loc[matching_indices_low, 'Load'] = -abs(extracted_data['Load']) #changed to neg
           extracted_data.loc[matching_indices_low, 'Rotation'] = -abs(extracted_data['Rotation']) #changed to neg
           WF_data_summary[specimen].append(min(extracted_data.loc[matching_indices_low, 'Load']))
        if any(mask_high):  # Correct way to check for at least one match
          matching_indices_high = [i for i, is_match in enumerate(mask_high) if is_match]
          extracted_data.loc[matching_indices_high, 'Folder'] = item[0]
          extracted_data.loc[matching_indices_high, 'Load'] = abs(extracted_data['Load']) #changed to pos
          extracted_data.loc[matching_indices_high, 'Rotation'] = abs(extracted_data['Rotation']) #changed to pos
          WF_data_summary[specimen].append(max(extracted_data.loc[matching_indices_high, 'Load']))

    extracted_data['Rho']=path_r
    all_data.append(extracted_data)
   
    #all_dataframe[curr_specimen] ={'Rotation':FR,'Load':FL,'Theta':path_t,'Rho':path_r}
    # Combine all data for the specimen into a single dataframe
    specimen_data_WF[curr_specimen] = pd.concat(all_data, ignore_index=True)

# Convert dictionary to Pandas DataFrame
WF_dat_sum = pd.DataFrame(WF_data_summary,index=ray_vals)

# Save as Excel or CSV
WF_dat_sum.to_excel(f"{specimen}_summary_WF.xlsx", index=False)  # Save as an Excel file
WF_dat_sum.to_csv(f"{specimen}_summary_WF.csv", index=False)  # Save as a CSV file

# In[]:
# Architecture for actually comparing slices
pos_list = {
  "folders": folders,
  "rows": [2,4,0,4,2,1,3,1,3,0,4,0],
  "cols":[5,2,1,3,0,0,5,5,0,3,1,2]
}
#"cols":[4,2,1,3,0,0,4,4,0,3,1,2] #OG before expanding

for i,specimen in enumerate(specimen_dirs):
    fig_big = plt.figure()
#    fig_big = plt.subplots(5,5)#, figsize=(6, 12))  
    fig_big.suptitle(f'Combined FE-LB Loading Behavior for {specimen}',fontsize=20)
    ax_pol_WF = plt.subplot2grid((5, 6), (1, 1), colspan=2,rowspan=2, polar=True)
    ax_pol_WF.plot(specimen_data_WF[specimen]['Theta-path-rad'],specimen_data_WF[specimen]['Rho-path'],linewidth=2,color='black')
    ax_pol_WF.set_title('Wake Combined') 
    
    ax_pol_MG = plt.subplot2grid((5, 6), (1, 3), colspan=2,rowspan=2, polar=True)
    ax_pol_MG.plot(np.radians(specimen_data_MG[specimen]['Theta'].values),abs(specimen_data_MG[specimen]['Rotation(Rotary:Rotation) (deg)'].values),linewidth=2,color='black')
    ax_pol_MG.set_title('McGill Combined') 
    
    save_folder = r'C:\Users\emmac\Documents\SBES\Brown Lab\McGill\Processing Files\Comparison Plots'
    spec_folder = os.path.join(save_folder, specimen) # Create a new subfolder for the specimen
    os.makedirs(spec_folder, exist_ok=True) # Ensure the directory exists

    for folder in folders:
        # Get data from the MG and WF relevant slices
        MG_subset = specimen_data_MG[specimen][specimen_data_MG[specimen]['Folder'] == folder]
        WF_subset = specimen_data_WF[specimen][specimen_data_WF[specimen]['Folder'] == folder]
        
# =============================================================================
#         # Plot them both on the same figure, for saving to folder
#         plt.figure()
#         plt.scatter(MG_subset['Torque(Rotary:Torque) (N·m)'],MG_subset['Rotation(Rotary:Rotation) (deg)'],c='#ED1B2F',s=20)
#         plt.scatter(WF_subset['Load'],WF_subset['Rotation'],c='#9E7E38',s=20)
#         plt.xlabel('Torque (Nm)')
#         plt.ylabel('Rotation (deg)')
#         plt.title(f'Torque vs Displacement Curve for {specimen} {folder}')
#         plt.legend(['McGill','Wake'])
#         # Save the file
#         plt.savefig(os.path.join(spec_folder, f'{specimen}_{folder}.png'))
# =============================================================================

        # Making the subplots around the big figure
        index = pos_list["folders"].index(folder)
        row = pos_list["rows"][index]
        col = pos_list["cols"][index]
        
        ax_sub = plt.subplot2grid((5, 6), (row, col))
#        ax_sub.scatter(MG_subset['Torque(Rotary:Torque) (N·m)'],MG_subset['Rotation(Rotary:Rotation) (deg)'],c='#ED1B2F',s=20) # You can add more colors if needed)
        ax_sub.plot(MG_subset['Torque(Rotary:Torque) (N·m)'],MG_subset['Rotation(Rotary:Rotation) (deg)'],color='#ED1B2F',linestyle='-') # You can add more colors if needed)
#        ax_sub.scatter(WF_subset['Load'],WF_subset['Rotation'],c='#9E7E38',s=20)
        ax_sub.plot(WF_subset['Load'],WF_subset['Rotation'],color='#9E7E38', linestyle='-')
        ax_sub.set_xlabel('Torque (Nm)')
        ax_sub.set_ylabel('Rotation (deg)')
        ax_sub.set_title(f'{folder}')
    ax_sub.legend(['McGill','Wake'])
# Plot formatting
#plt.tight_layout()
# plt.subplots_adjust(left=1,
#                       bottom=1, 
#                       right=1.2, 
#                       top=1.2, 
#                       wspace=4, 
#                       hspace=4)
plt.show()

# In[]:
import os
import matplotlib.pyplot as plt

for i, specimen in enumerate(specimen_dirs):
    # Create one big figure for this specimen
    fig_big = plt.figure(figsize=(12, 12))
    fig_big.suptitle(f'Combined FE-LB Loading Behavior for {specimen}', fontsize=20)

    # Polar slice plot in the middle (row=1, col=1, spanning 3x3 grid spaces)
    ax_pol = plt.subplot2grid((5, 5), (1, 1), colspan=3, rowspan=3, polar=True, figure=fig_big)
    ax_pol.plot(specimen_data_WF[specimen]['Theta-path-rad'], specimen_data_WF[specimen]['Rho-path'], linewidth=2, color='black')

    # Create the folder for saving images
    save_folder = r'C:\Users\emmac\Documents\SBES\Brown Lab\McGill\Processing Files\Comparison Plots'
    spec_folder = os.path.join(save_folder, specimen)
    os.makedirs(spec_folder, exist_ok=True)

    # Iterate through folders, alternating between subplots and standalone figures
    for j, folder in enumerate(folders):
        # Get data from the MG and WF relevant slices
        MG_subset = specimen_data_MG[specimen][specimen_data_MG[specimen]['Folder'] == folder]
        WF_subset = specimen_data_WF[specimen][specimen_data_WF[specimen]['Folder'] == folder]

        if j % 2 == 0:
            # Plot as a subplot in fig_big using the pre-defined positions
            if folder in pos_list["folders"]:
                index = pos_list["folders"].index(folder)
                row = pos_list["rows"][index]
                col = pos_list["cols"][index]

                ax_sub = plt.subplot2grid((5, 5), (row, col), figure=fig_big)
                ax_sub.scatter(MG_subset['Torque(Rotary:Torque) (N·m)'], MG_subset['Rotation(Rotary:Rotation) (deg)'], c='#ED1B2F', s=20)
                ax_sub.scatter(WF_subset['Load'], WF_subset['Rotation'], c='#9E7E38', s=20)
                ax_sub.set_xlabel('Torque (Nm)')
                ax_sub.set_ylabel('Rotation (deg)')
                ax_sub.set_title(f'{folder}')
                ax_sub.legend(['McGill', 'Wake'])

        else:
            # Create a separate figure
            fig_single = plt.figure(figsize=(6, 4))
            plt.scatter(MG_subset['Torque(Rotary:Torque) (N·m)'], MG_subset['Rotation(Rotary:Rotation) (deg)'])
            plt.scatter(WF_subset['Load'], WF_subset['Rotation'])
            plt.xlabel('Torque (Nm)')
            plt.ylabel('Rotation (deg)')
            plt.title(f'Torque vs Displacement Curve for {specimen} {folder}')
            plt.legend(['McGill', 'Wake'])
            
            # Save the separate figure
            plt.savefig(os.path.join(spec_folder, f'{specimen}_{folder}.png'))
            plt.close(fig_single)  # Close the figure to free memory

    # Save the big figure after all subplots are added
    plt.savefig(os.path.join(spec_folder, f'{specimen}_combined.png'))
    plt.close(fig_big)  # Close the big figure to free memory

