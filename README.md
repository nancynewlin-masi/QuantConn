# QuantConn

This code was used to process Diffusion-Weighted Images (DWI) for the QuantConn Challenge.

## Installation
Pull the github repo. 
All libraries needed for processing will be set up with singularity build (mrtrix, fsl, freesurfer, dipy, nibabel, python, etc)

## Usage
Build the singularity.
sudo singularity build --sandbox Prototype NancysSingularity
Run the singularity.
You will need to bind directories for (1) Diffusion data, (2) Freesurfer output, and (3) output directory.
sudo singularity shell --bind /path/to/dwi/:/DIFFUSION/,/path/to/freesurfer/:/FREESURFER/,/path/for/outputs/:/OUTPUTS/  --writable test1

### Expected contents of /path/to/freesurfer/
* The full output from running freesurfer on a T1 from the subject. (Has mri/ directory)
* Example freesurfer command for linux: recon-all -i ${T1wImage} -subjid ${Name of subject specific dir} -sd ${Location of freesurfer installation} -all

### Expected contents of /path/to/dwi/
* We expect the names to have "dwi" and extnsions ".nii.gz", ".bvec", and ".bval"

## Overview of processing
When running "singularity run ...", /CODE/main.sh is executed. This script runs the following processing: 
* Tensor fitting
* b0 extraction
* Extract Desikan-Killany ROIs from aparc+aseg.nii.gz (freesurfer output)
* Registration between freesurfer parcellation and diffusion b0
* Estimate response functions
* Get fiber orientation distribution functions (fODFs)
* Get 5tt mask
* Get GMWM boundary
* Tractography
* Connectomics
* Compute graph measures from connectomes
