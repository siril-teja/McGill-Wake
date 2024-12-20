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

# Define the list of folders and the parent directory for the specimens
#pre_filename = r'X:\01_people\Coltoff\Brown Lab Files\Dissertation Data\McGill-Wakeforest Testing'
pre_filename = r'C:\Users\emmac\Documents\SBES\Brown Lab\McGill\Data from Testing\McGill\McGill-Wakeforest Testing'
folders = ['0-180', '105-285', '120-300', '135-315', '15-195',
           '150-330', '165-345', '30-210', '45-225', '60-240', '75-255', '90-270']
# Replace with actual specimen directory names
specimen_dirs = ['McGill Spec 1', 'McGill Spec 2', 'McGill Spec 3', 'Sawbones']

# Initialize a dictionary to hold the data for each specimen
specimen_data = {specimen: pd.DataFrame() for specimen in specimen_dirs}

# Loop through each specimen and process the folders
for specimen in specimen_dirs:
    all_data = []  # List to hold data for the current specimen
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
            extracted_data['Folder'] = folder
            all_data.append(extracted_data)
            
            # Plotting the data:
            fig=plt.figure()
            plt.scatter(df['Torque(Rotary:Torque) (N·m)'],extracted_data['Rotation(Rotary:Rotation) (deg)'])
            plt.xlabel('Torque (Nm)')
            plt.ylabel('Rotation (deg)')
            plt.title(f'Torque vs Displacement Curve for {specimen} {folder}')
            # Save the file
            plt.savefig(os.path.join(r'C:\Users\emmac\Documents\SBES\Brown Lab\McGill\Processing Files\Figures', f'{specimen}_{folder}.png'))
        else:
            print(f"File not found: {file_path}")

    # Combine all data for the specimen into a single dataframe
    specimen_data[specimen] = pd.concat(all_data, ignore_index=True)

# Now specimen_data contains a dataframe for each specimen
# You can access each dataframe using specimen_data['Specimen1'], specimen_data['Specimen2'], etc.

# Example: Save each dataframe to a CSV file
for specimen, data in specimen_data.items():
    output_file = f"{specimen}_data.csv"
    data.to_csv(output_file, index=False)
    print(f"Saved data for {specimen} to {output_file}")

# In[]:
# To incorporate surfaces into slice comparisons
    # Get all test files in folder
def get_xlsx_files(folder_path):
    xlsx_files = [os.path.join(folder_path, file) for file in os.listdir(folder_path) if file.endswith('.xlsx')]
    return xlsx_files

# Choose data import folder
filepath = r'C:\Users\emmac\Documents\SBES\Brown Lab\McGill\Data from Testing\McGill\FE-LB Trajectories' #Home Working Folder
xlsx_files_list = get_xlsx_files(filepath)
print(xlsx_files_list)

# Dictionary to hold DataFrames
dataframes_dict = {}

# Iterate over file names
for file_name in xlsx_files_list:
    df_name = file_name.split('.')[0]
    df_name = df_name.split('\\')[-1]
    df_name = file_name.split(df_name)[0] + df_name
    # Add DataFrame to the dictionary
    dataframes_dict[df_name] = file_name

# Create a DataFrame of DataFrames
all_dataframe = pd.DataFrame.from_dict(dataframes_dict, orient='index')

# Now outer_dataframe is a DataFrame of DataFrames
print(all_dataframe)

file_path = Path("/home/user/documents/example_file.txt")
search_string = "documents"

if search_string in str(file_path):
    print(f"The path contains '{search_string}'.")
else:
    print(f"The path does not contain '{search_string}'.")

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
# 2) Removing NANs
def removeNANS(d):
    value_to_remove = "#NV"
    df_data = d[~((d['LB_rot'] == value_to_remove) | (d['FE_rot'] == value_to_remove))] 
    return df_data

# In[]:
# 3) Filtering
def signalfilt(load,disp,poles,Fs,Fc):
    sos=butter(poles,1.65*Fc,fs=Fs, output='sos')
    x = sosfiltfilt(sos,load)
    y = sosfiltfilt(sos,disp)
    return (x,y)

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

# Two Path Polar Plot
def plotprepost(pre_x,pre_y,post_x,post_y): # add in lim variable?
    fig = plt.figure(figsize=(15,15))
    plt.plot(pre_x,pre_y) #[0:lim]
    plt.plot(post_x,post_y) #[0:lim]
    plt.show()
    return fig

# In[]:
# 5) Calculate Stiffness
#FU: Will need to adapt this to use anything other than LB/FE rot/torq (perhaps make array to call columns from in tuple list)
def stiffness(D):
    disps=np.concatenate([np.array(D['LB_rot'])[:,np.newaxis],np.array(D['FE_rot'])[:,np.newaxis]],axis=1)
    FR=np.sqrt(np.sum(disps**2,axis=1)) # resultant ROM
    FR_sign=np.multiply(FR,np.sign(D['FE_rot']))
    #FR_sign = np.multiply(FR, np.where(np.abs(D['LB_rot']) >= np.abs(D['FE_rot']), np.sign(D['LB_rot']), np.sign(D['FE_rot'])))
    dDLB=np.diff(D['LB_rot'])[:,np.newaxis]#.T
    dDFE=np.diff(D['FE_rot'])[:,np.newaxis]#.T
    dD=np.concatenate([dDLB,dDFE],axis=1)
    
    loads=np.concatenate([np.array(D['LB_torq'])[:,np.newaxis],np.array(D['FE_torq'])[:,np.newaxis]],axis=1)
    FL=np.sqrt(np.sum(loads**2,axis=1)) # resultant ROM
    FL_sign=np.multiply(FL,np.sign(D['FE_rot']))
    #FL_sign = np.multiply(FL, np.where(np.abs(D['LB_rot']) >= np.abs(D['FE_rot']), np.sign(D['LB_rot']), np.sign(D['FE_rot'])))
    dFLB=np.diff(D['LB_torq'])[:,np.newaxis]#.T
    dFFE=np.diff(D['FE_torq'])[:,np.newaxis]#.T
    dF=np.concatenate([dFLB,dFFE],axis=1)
    
    dFdD=np.concatenate([np.divide(dFLB,dDLB),np.divide(dFFE,dDFE)],axis=1)
    dFdD_rot=np.sqrt(np.sum(dFdD**2,axis=1))
    return FR, FR_sign, FL, dD, dF, dFdD, dFdD_rot, FL_sign

# In[]:
# Picking which surface you want to represent
# Decide if doing Inward/Outward vs Clockwise/Counterclockwise
# FU: Consider doing a title var that triggers title on plot in next block depending on selection
def surf_choose(choice):
    print(choice)
    surf = []
    if choice == 1:
        surf = dR_in 
    elif choice == 2: 
        surf = dR_out
    elif choice == 3: 
        surf = dR_neutral
    elif choice == 4: 
        surf = dT_CW
    elif choice == 5: 
        surf = dT_CCW
    elif choice == 6: 
        surf = dT_neutral
    elif choice == 0:
        surf = dD_res_filter
    return surf

# In[]:
# Function version of above
def surf_gen(df,ind):
    # ind var will be used to determine load vs stiffness as z variable
    if (ind == "load"):
        output  = sp.interpolate.bisplrep(df['LB_rot'],df['FE_rot'],df['FL_sign'], full_output=1, kx=3, ky=3) #Fits a bspline curve to surface
#        output  = sp.interpolate.bisplrep(df['LB_rot'],df['FE_rot'],df['FL'], full_output=1, kx=3, ky=3) #Fits a bspline curve to surface
    elif(ind == "stiff"):
        output  = sp.interpolate.bisplrep(df['LB_rot'],df['FE_rot'],df['dFdD_rot'], full_output=1, kx=3, ky=3) #Fits a bspline curve to surface
    else:
        print("Please select a valid value of 'load' or 'stiff'.")
    tck = output[0] #Used later for evaluating the surface at specific points
    grid_resolution = 1000
    # Test non-polar meshgrid definition
    xt = np.linspace(np.ceil(np.min(surf_df['LB_rot'])), np.ceil(np.max(surf_df['LB_rot'])), grid_resolution)
    yt = np.linspace(np.ceil(np.min(surf_df['FE_rot'])), np.ceil(np.max(surf_df['FE_rot'])), grid_resolution)
    xv, yv = np.meshgrid(xt, yt)

    zv = np.array([[sp.interpolate.bisplev(x,y,tck) for (x,y) in zip(x_list,y_list)] for (x_list,y_list) in zip(xv,yv)]) 

    Z = zv
    Z = (Z-Z.min())/(Z.max()-Z.min())

    tick_max=np.ceil(np.max(zv)) # for figure scaling, based on max expected stiffness
    return xv,yv,zv
# In[]:
# Function version of above
def compute_2D_convex_hull(pts_array):
    hull = ConvexHull(pts_array)
    return hull

def compute_3D_convex_hull(points3D):
    hull3D = ConvexHull(points3D)
    return hull3D

def convex_surf(df,surfx,surfy,surfz):
    curr_points=[df['LB_rot'].to_numpy().astype(float), df['FE_rot'].to_numpy().astype(float)]
    pts_array = np.column_stack(curr_points)
    # Convex Hull
    hull = ConvexHull(pts_array)
    
    xs = surfx.flatten()
    ys = surfy.flatten()
    zs = surfz.flatten()
    points3D = np.column_stack((xs, ys, zs))
    
    with ThreadPoolExecutor() as executor:
    
        with tqdm(total=2, desc="Computing Convex Hulls") as progress:
            future_2D_hull = executor.submit(compute_2D_convex_hull, pts_array)
            future_3D_hull = executor.submit(compute_3D_convex_hull, points3D)
    
            hull = future_2D_hull.result()
            progress.update(1)
    
            hull3D = future_3D_hull.result()
            progress.update(1)
    
    # To Polar
    xLim = np.array([pts_array[simplex, 0] for simplex in np.array(hull.vertices)])
    yLim = np.array([pts_array[simplex, 1] for simplex in np.array(hull.vertices)])
    #bound_r,bound_phi = cart2pol(xLim, yLim)
    
    # Generating the mask from the 2D convex hull for the 3D points
    path = Path(pts_array[hull.vertices])
    mask = path.contains_points(points3D[:, :2])
    
    # Applying the mask to filter 3D points
    masked_points3D = points3D[mask]
    tick_max=np.round(np.max(masked_points3D[:, 2]),1)
    
    # Plotting the filtered 3D points
    # fig = plt.figure(figsize=(10, 8))
    # ax = fig.add_subplot(111, projection='3d')
    # ax.scatter(masked_points3D[:, 0], masked_points3D[:, 1], masked_points3D[:, 2], c=masked_points3D[:, 2], marker="o", cmap="Reds")
    # ax.scatter(df['LB_rot'],df['FE_rot'],0,c='silver')
    # ax.set_xlabel('LB Loading (deg)')
    # ax.set_ylabel('FE Loading (deg)')
    # ax.set_zlabel('Stiffness (Nm/deg)')
    # ax.set_zlim(0,tick_max)
    # plt.title('3D Points within the 2D Convex Hull')
    # plt.show()
    return masked_points3D, xLim, yLim
# In[]:
def in_out_plots(vals_out,vals_in):
#    xo,yo,zo = surf_gen(vals_out,"stiff")
    xo,yo,zo = surf_gen(vals_out,"load")
    O_masked_points3D, xOLim, yOLim = convex_surf(vals_out,xo,yo,zo)
#    xi,yi,zi = surf_gen(vals_in,"stiff")
    xi,yi,zi = surf_gen(vals_in,"load")
    I_masked_points3D, xILim, yILim = convex_surf(vals_in,xi,yi,zi)
    return O_masked_points3D, I_masked_points3D
# In[]:
# For finding important slice angles
def inward_outward_angle_fit(angle,tol,pringle_out,pringle_in):
    sliceO_fit, sliceRO_sample, sliceTO_sample, sliceXO_sample, sliceYO_sample, filtered_pringleO, sign_filtered_pringleO = pringle_angle(pringle_out,angle,tol) 
    sliceI_fit, sliceRI_sample, sliceTI_sample, sliceXI_sample, sliceYI_sample, filtered_pringleI, sign_filtered_pringleI = pringle_angle(pringle_in,angle,tol)
    return sliceO_fit, sliceRO_sample,sliceI_fit, sliceRI_sample
# In[]:
def pringle_angle(masked_points3D, slice_angle, tol):
    mask_r,mask_t=cart2pol(masked_points3D[:,0],masked_points3D[:,1])
    point_set=np.column_stack((mask_r, mask_t,masked_points3D[:,2]))
    # Extract the necessary columns (first and second columns)
    selected_columns = point_set[:, :3]
    
    tolerance = np.radians(tol)
    input_angle = np.radians(slice_angle) #np.radians((angle + 180)%360) 
    opposite_angle = np.radians( (slice_angle + 180) % 360 )
    ratio = np.array([input_angle-tolerance, input_angle+tolerance, opposite_angle-tolerance, opposite_angle+tolerance])
    
    # Create a boolean mask
    if slice_angle == 0:
          boolmask = (((mask_t >= 2*np.pi+ratio[0]) & (mask_t < 2*np.pi)) | \
                     (mask_t <= ratio[1]) | \
                     (mask_t >= ratio[2]) & (mask_t <= ratio[3]))
    else:
        boolmask = ((mask_t >= ratio[0]) & (mask_t <= ratio[1])) | \
               ((mask_t >= ratio[2]) & (mask_t <= ratio[3]))
                
    # Apply the mask to filter the rows
    filtered_pringle = selected_columns[boolmask]
    sign_filtered_pringle = filtered_pringle
    if slice_angle == 0:
        sign_mask = ((filtered_pringle[:, 1] > ratio[2]) & (filtered_pringle[:, 1] <= ratio[3]))
        sign_filtered_pringle[sign_mask, 0] *= -1
    else:
        sign_mask = filtered_pringle[:, 1] > np.pi
        sign_filtered_pringle[sign_mask, 0] *= -1

    # Determining parameters for polyline generation
    npoly=3
    npts=300   
    slice_fit = np.poly1d(np.polyfit(sign_filtered_pringle[:,0], sign_filtered_pringle[:,2], npoly))
    sliceR_sample = np.linspace(min(sign_filtered_pringle[:,0]),max(sign_filtered_pringle[:,0]),npts)
    sliceT_sample = np.ones(npts)*np.radians(slice_angle)
    sliceX_sample,sliceY_sample = pol2cart(sliceR_sample, sliceT_sample)
    return slice_fit, sliceR_sample, sliceT_sample, sliceX_sample, sliceY_sample, filtered_pringle, sign_filtered_pringle
# In[]:
minimax=[]
for filename in xlsx_files_list:
#filename=xlsx_files_list[0]
    print(filename)
    # Pick one or the other based on moment or displacement control (or hybrid)
    #hybrid = int(input(" 0 = Displacement Control, 1 = Force Control, 2 = Hybrid Control"))
    hybrid = 0
    Time = pd.read_excel(filename,sheet_name='Timing.Sync Trigger') # Time
    Time.rename(columns = {'Setpoint Time':'Time'}, inplace = True)
    if (hybrid==0):
        AppliedDisp = pd.read_excel(filename,sheet_name='Kinematics.JCS.Control') # Disp control applied rotations & translations
        AppliedDisp.rename(columns = {'Anterior Translation - Control':'Anterior', 'Superior Translation - Control':'Superior',
                                     'Right Lateral Translation - Control':'Lateral',  'Right Lateral Bending Angle - Control': 'LB',
                                      'Left Axial Rotation Angle - Control':'AR','Extension Angle - Control':'FE'}, inplace = True)
        MeasuredLoad = pd.read_excel(filename,sheet_name='State.JCS Load') # Disp control measured forces & torques
        MeasuredLoad.rename(columns = {'JCS Load Posterior Shear':'Posterior', 'JCS Load Compression':'Compression',
                                     'JCS Load Left Lateral Shear':'Lateral',  'JCS Load Left lateral Bending Torque': 'LB',
                                      'JCS Load Right Axial Rotation Torque':'AR','JCS Load Flexion Torque':'FE'}, inplace = True)
    elif(hybrid==1):
        AppliedLoad = pd.read_excel(filename,sheet_name='Kinetics.JCS.Control') # Force control applied forces & moments
        AppliedLoad.rename(columns = {'Posterior Shear - Control':'Posterior', 'Compression - Control':'Compression',
                                     'Left Lateral Shear - Control':'Lateral',  'Left Lateral Bending Torque - Control': 'LB',
                                      'Right Axial Rotation Torque - Control':'AR','Flexion Torque - Control':'FE'}, inplace = True)
        MeasuredDisp_JCS = pd.read_excel(filename,sheet_name='State.C4-C5 JCS') # Force control JCS rotations & translations
        MeasuredDisp_JCS.rename(columns = {'JCS_Anterior':'Anterior', 'JCS_Superior':'Superior',
                                     'JCS_Lateral':'Lateral',  'JCS_Lateral Bending': 'LB',
                                      'JCS_Axial Rotation':'AR','JCS_Extension':'FE'}, inplace = True)
    elif(hybrid==2):
        print("uhhh idk man, haven't figured this part out yet")
    else:        
        print("Please enter a valid hybrid control number.")
        hybrid = int(input(" 0 = Displacement Control, 1 = Force Control, 2 = Hybrid Control"))
    
    # Clean-up & Formatting
    dfdata = convertoDF(MeasuredLoad,AppliedDisp,Time,0)
    dfclean = removeNANS(dfdata)
   
    # Filtering
    tstep=dfclean['Time'][len(dfclean['Time'])-1]-dfclean['Time'][0]
    N=len(dfclean['Time'])
    Fs=N/tstep
    Fc=0.09
    poles=4

    Ant_trans,Pos_load = signalfilt(dfclean['ant_trans'],dfclean['pos_load'],poles,Fs,Fc)
    Sup_trans,Comp_load = signalfilt(dfclean['sup_trans'],dfclean['comp_load'],poles,Fs,Fc)
    Lat_trans,Lat_load = signalfilt(dfclean['lat_trans'],dfclean['lat_load'],poles,Fs,Fc)
    FE_rot,FE_torq = signalfilt(dfclean['FE_rot'],dfclean['FE_torq'],poles,Fs,Fc)
    LB_rot,LB_torq = signalfilt(dfclean['LB_rot'],dfclean['LB_torq'],poles,Fs,Fc)
    AR_rot,AR_torq = signalfilt(dfclean['AR_rot'],dfclean['AR_torq'],poles,Fs,Fc)
    
    dffiltered = pd.DataFrame()
    dffiltered['ant_trans']=Ant_trans
    dffiltered['sup_trans']=Sup_trans
    dffiltered['Lat_trans']=Lat_trans
    dffiltered['FE_rot']=FE_rot
    dffiltered['LB_rot']=LB_rot
    dffiltered['AR_rot']=AR_rot
    dffiltered['pos_load']=Pos_load
    dffiltered['comp_load']=Comp_load
    dffiltered['lat_load']=Lat_load
    dffiltered['FE_torq']=FE_torq
    dffiltered['LB_torq']=LB_torq
    dffiltered['AR_torq']=AR_torq
    
    # 4) Compute Polar Paths & Derivatives
    x=dffiltered['LB_rot'].to_numpy().astype(float)
    y=dffiltered['FE_rot'].to_numpy().astype(float)

    [path_r,path_t,path_dr,path_dt]=cart2pol_vel(x,y)
    
    dffull=dffiltered
    dffull['time']=Time
    dffull['LB_FE_r']=path_r
    dffull['LB_FE_t']=path_t
    dffull['LB_FE_dr']=np.append(path_dr, 0)
    dffull['LB_FE_dt']=np.append(path_dt, 0)
    
    # Calling stiffness calculation
    [FR, FR_sign, FL, dD, dF, dFdD, dFdD_rot, FL_sign]=stiffness(dffull)
        
    # Store all values with derivatives & stiffness
    dffull['FR']=FR
    dffull['FR_sign']=FR_sign
    dffull['FL']=FL
    dffull['FL_sign']=FL_sign
    dffull['dD_x']=np.append(dD[:,0], 0)
    dffull['dD_y']=np.append(dD[:,1], 0)
    dffull['dF_x']=np.append(dF[:,0], 0)
    dffull['dF_y']=np.append(dF[:,1], 0)
    dffull['dFdD_x']=np.append(dFdD[:,0], 0)
    dffull['dFdD_y']=np.append(dFdD[:,1], 0)
    dffull['dFdD_rot']=np.append(dFdD_rot, 0)
