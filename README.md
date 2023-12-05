# QuantConn

This code was used to process Diffusion-Weighted Images (DWI) for the QuantConn Challenge.
QuantConn contributors: 

**Nancy R. Newlin**, Vanderbilt University, Nashville, TN

**Neda Jahanshad**, Keck School of Medicine of USC, Los Angeles, CA

**Kurt Schilling**, Vanderbilt University, Nashville, TN

**Daniel Moyer**, Vanderbilt University, Nashville, TN

**Eleftherios Garyfallidis**, Indiana University Bloomington, Bloomington, IN

**Bennett A. Landman**, Vanderbilt University, Nashville, TN

**Serge Koudoro**,	Indiana University Bloomington, Bloomington, IN

**Bramsh Chandio**, Keck School of Medicine of USC, Los Angeles, CA


http://cmic.cs.ucl.ac.uk/cdmri/challenge.html

## Installation
Pull the github repo. 
All libraries needed for processing will be set up with singularity build (mrtrix, fsl, freesurfer, dipy, nibabel, python, etc)

## Usage
Build the singularity.

`sudo singularity build --sandbox Prototype NancysSingularity`
Run the singularity.
You will need to bind directories for (1) Diffusion data, (2) Freesurfer output, and (3) output directory.

`sudo singularity shell --bind /path/to/dwi/:/DIFFUSION/,/path/to/freesurfer/:/FREESURFER/,/path/for/outputs/:/OUTPUTS/  --writable test1`

### Expected contents of /path/to/freesurfer/
* The full output from running freesurfer on a T1 from the subject. (Has `mri/` directory)
* Example freesurfer command for linux: `recon-all -i ${T1wImage} -subjid ${Name of subject specific dir} -sd ${Location of freesurfer installation} -all`

### Expected contents of /path/to/dwi/
* We expect the names to have `"dwi"` and extnsions `".nii.gz"`, `".bvec"`, and `".bval"`

## Overview of processing
When running `singularity run ...`, /CODE/main.sh is executed. This script runs the following processing: 
* Tensor fitting
* b0 extraction
* Extract Desikan-Killany ROIs from `aparc+aseg.nii.gz` (freesurfer output)
* Registration between freesurfer parcellation and diffusion b0
* Estimate response functions
* Get fiber orientation distribution functions (fODFs)
* Get 5tt mask
* Get GMWM boundary
* Tractography
* Connectomics
* Compute graph measures from connectomes

# Citations
MRTrix: 
* Tournier, J. D., Smith, R., Raffelt, D., Tabbara, R., Dhollander, T., Pietsch, M., Christiaens, D., Jeurissen, B., Yeh, C. H., & Connelly, A. (2019). MRtrix3: A fast, flexible and open software framework for medical image processing and visualisation. NeuroImage, 202, 116137. https://doi.org/10.1016/J.NEUROIMAGE.2019.116137

DiPy:
* Garyfallidis, E., Brett, M., Amirbekian, B., Rokem, A., van der Walt, S., Descoteaux, M., & Nimmo-Smith, I. (2014). Dipy, a library for the analysis of diffusion MRI data. Frontiers in Neuroinformatics, 8(FEB). https://doi.org/10.3389/FNINF.2014.00008/ABSTRACT

Brain Connectivity Toolbox: 
* Rubinov, M., & Sporns, O. (2010). Complex network measures of brain connectivity: uses and interpretations. NeuroImage, 52(3), 1059–1069. https://doi.org/10.1016/J.NEUROIMAGE.2009.10.003

Streamline Count Invariant adjustment to complex network measures:
* Newlin, N. R., Rheault, F., Schilling, K. G., & Landman, B. A. (2023). Characterizing Streamline Count Invariant Graph Measures of Structural Connectomes. Journal of Magnetic Resonance Imaging. https://doi.org/10.1002/JMRI.28631

FSL: 
* Jenkinson, M., Beckmann, C. F., Behrens, T. E. J., Woolrich, M. W., & Smith, S. M. (2012). FSL. NeuroImage, 62(2), 782–790. https://doi.org/10.1016/J.NEUROIMAGE.2011.09.015

