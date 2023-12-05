# Directories
export DIFFDIR=/QuantConn/DIFFUSION/
export FREESURFERDIR=/QuantConn/FREESURFER/
export OUTPUTDIR=/QuantConn/OUTPUTS/

echo "NOTE: Beginning connectomics analysis with diffusion data at: ${DIFFDIR}, freesurfer output at: ${FREESURFERDIR}."
echo "NOTE: Output will be stored at ${OUTPUTDIR}"

# Hyper parameters
export NUMSTREAMS=100   #5000000
export WORKINGDIR=/QuantConn/
export FREESURFER_HOME=/QuantConn/APPS/freesurfer/freesurfer/
source $FREESURFER_HOME/SetUpFreeSurfer.sh

# Set up temporary directory that will be deleted at the end of processing
export TEMPDIR=/QuantConn/TEMP/


# Define look up tables for atlas. This one is for desikan killany only (freesurfer default)
export LUT=/QuantConn/SUPPLEMENTAL/FreeSurferColorLUT.txt
export FS=/QuantConn/SUPPLEMENTAL/fs_default.txt

#echo "Moving dwi to accre..."
#scp newlinnr@hickory.accre.vanderbilt.edu:${DIFFDIR}/* newlinnr@hickory.accre.vanderbilt.edu:${TEMPDIR}
echo "Check for DWI"
export DWI=$(find $DIFFDIR -name "*dw*i.nii.gz")
export BVEC=$(find $DIFFDIR -name "*bvec")
export BVAL=$(find $DIFFDIR -name "*bval")

echo "DWI found at ${DWI}, ${BVEC}, ${BVAL}"

echo "Check for T1"
if test -f "${FREESURFERDIR}/mri/orig/001.mgz"; then
    export T1_freesurfer=${FREESURFERDIR}/mri/orig/001.mgz
else
    echo "Please provide a valid T1 image."
    exit 0;
fi
echo ${BVEC} ${BVAL}
dwi2tensor ${DWI} ${TEMPDIR}/dti.nii.gz -fslgrad  ${BVEC} ${BVAL}
tensor2metric ${TEMPDIR}/dti.nii.gz -fa ${TEMPDIR}/fa.nii.gz

echo "Getting T1 and aparc+aseg from accre (freesurfer output)..."
export T1=${TEMPDIR}/T1.nii.gz
mrconvert ${T1_freesurfer} ${T1}
mrconvert ${FREESURFERDIR}/mri/aparc+aseg.mgz ${TEMPDIR}/aparc+aseg.nii.gz

if test -f "${TEMPDIR}/T1_inDWIspace.nii.gz"; then
        echo "Results found. Continue past registration..."
else
echo "Extract B0..."
dwiextract ${DWI} -fslgrad ${BVEC} ${BVAL} - -bzero |  mrmath - mean ${TEMPDIR}/b0.nii.gz -axis 3

echo "Run bet on t1..."
bet ${T1} ${TEMPDIR}/T1_bet.nii.gz

echo "Labelconvert to get the Desikan Killany atlas..."
# big atlas with many regions -> desikan killany
labelconvert ${TEMPDIR}/aparc+aseg.nii.gz $LUT $FS ${TEMPDIR}/atlas_freesurfer_t1.nii.gz

echo "Apply transforms to atlas image to register to subject space..."
epi_reg --epi=${TEMPDIR}/b0.nii.gz --t1=${T1} --t1brain=${TEMPDIR}/T1_bet.nii.gz --out=${TEMPDIR}/b02t1

echo "Convert transform to go in oppisite direction"
convert_xfm -omat ${TEMPDIR}/t12b0.mat -inverse ${TEMPDIR}/b02t1.mat

echo "Apply transform to T1"  # ${TEMPDIR}/T1_bet.nii.gz
flirt -in ${T1} -ref ${TEMPDIR}/b0.nii.gz -applyxfm -init ${TEMPDIR}/t12b0.mat  -out ${TEMPDIR}/T1_inDWIspace.nii.gz
if test -f "${TEMPDIR}/T1_inDWIspace.nii.gz"; then
    echo "CHECK: Registered T1 found. Proceeding to next step."
else
    echo "ERROR FOUND: Registration failed. Exiting"
    exit 0;
fi
fi
echo "Apply transform to atlas"
flirt -in ${TEMPDIR}/atlas_freesurfer_t1.nii.gz -ref ${TEMPDIR}/b0.nii.gz -applyxfm -init ${TEMPDIR}/t12b0.mat -out ${TEMPDIR}/atlas_freesurfer_subj.nii.gz  -interp nearestneighbour
flirt -in ${TEMPDIR}/aparc+aseg.nii.gz -ref ${TEMPDIR}/b0.nii.gz -applyxfm -init ${TEMPDIR}/t12b0.mat -out ${TEMPDIR}/aparc+aseg_inDWIspace.nii.gz  -interp nearestneighbour

echo "Saving atlas as ${TEMPDIR}/atlas_freesurfer_subj.nii.gz..."
export ATLAS=${TEMPDIR}/atlas_freesurfer_subj.nii.gz

echo "Estimate response functions for wm,gm, and csf..."
# Estimate response functions
dwi2response tournier ${DWI} ${TEMPDIR}/sfwm.txt -fslgrad ${BVEC} ${BVAL}

echo "Get FOD functions from the estimated response function -single fiber white matter only-..."
# Make FOD functions
echo "Checking how many shells dwi2response found..."
nr_lines=$(wc -l < ${TEMPDIR}/sfwm.txt)
if [ $nr_lines -le 4 ]; then
    echo "Single shell acquisition."
    dwi2fod csd ${DWI} ${TEMPDIR}/sfwm.txt ${TEMPDIR}/wmfod.nii.gz  -fslgrad ${BVEC} ${BVAL}
else
    echo "Multishell acquisition detected."
    dwi2response dhollander ${DWI} ${TEMPDIR}/sfwm.txt ${TEMPDIR}/gm.txt ${TEMPDIR}/csf.txt -fslgrad ${BVEC} ${BVAL}
    dwi2fod msmt_csd ${DWI} ${TEMPDIR}/sfwm.txt ${TEMPDIR}/wmfod.nii.gz  ${TEMPDIR}/gm.txt ${TEMPDIR}/gmfod.nii.gz  ${TEMPDIR}/csf.txt ${TEMPDIR}/csffod.nii.gz -fslgrad ${BVEC} ${BVAL}
fi

echo "Use FODfs to get 5tt mask..."
# Get 5tt mask
5ttgen freesurfer ${TEMPDIR}/aparc+aseg_inDWIspace.nii.gz ${TEMPDIR}/5tt_image.nii.gz

echo "Use 5tt mask to get the GM/WM boundary..."
# Get Grey matter -White matter boundary
5tt2gmwmi ${TEMPDIR}/5tt_image.nii.gz ${TEMPDIR}/gmwmSeed.nii.gz

echo "Start tracking using probabilistic ACT..."
# Generate 10 million streamlines
# Takes time, and will be several GB of space
tckgen -act ${TEMPDIR}/5tt_image.nii.gz -backtrack -seed_gmwmi ${TEMPDIR}/gmwmSeed.nii.gz -select ${NUMSTREAMS} ${TEMPDIR}/wmfod.nii.gz ${TEMPDIR}/tractogram_${NUMSTREAMS}.tck

echo "Save tck file as TCK_FILE=${TEMPDIR}/tractogram_${NUMSTREAMS}.tck..."
export TCK_FILE=${TEMPDIR}/tractogram_${NUMSTREAMS}.tck

echo "Map tracks to Connectomes -NOS, Mean Length-, guided by atlas..."
# Map tracks to connectome (weighted by NOS)
tck2connectome ${TCK_FILE} ${ATLAS} ${TEMPDIR}/CONNECTOME_Weight_NUMSTREAMLINES_NumStreamlines_${NUMSTREAMS}.csv -symmetric

python /CODE/convertconnectometonp_nos.py  ${TEMPDIR}/CONNECTOME_Weight_NUMSTREAMLINES_NumStreamlines_${NUMSTREAMS}.csv  ${TEMPDIR}/CONNECTOME_NUMSTREAM.npy ${NUMSTREAMS}

# Map tracks to connectome (weighted by Mean Length of streamline)
tck2connectome ${TCK_FILE} ${ATLAS} ${TEMPDIR}/CONNECTOME_Weight_MEANLENGTH_NumStreamlines_${NUMSTREAMS}.csv -scale_length -stat_edge mean -symmetric
# Convert to npy
python /CODE/convertconnectometonp.py  ${TEMPDIR}/CONNECTOME_Weight_MEANLENGTH_NumStreamlines_${NUMSTREAMS}.csv ${TEMPDIR}/CONNECTOME_LENGTH.npy

tensor2metric ${TEMPDIR}/dti.nii.gz -fa ${TEMPDIR}/fa.nii.gz
tcksample ${TCK_FILE} ${TEMPDIR}/fa.nii.gz ${TEMPDIR}/mean_FA_per_streamline.csv -stat_tck mean
tck2connectome ${TCK_FILE} ${ATLAS} ${TEMPDIR}/CONNECTOME_${ID}_Weight_MeanFA_NumStreamlines_${NUMSTREAMS}.csv -scale_file ${TEMPDIR}/mean_FA_per_streamline.csv -stat_edge mean

python /CODE/convertconnectometonp.py  ${TEMPDIR}/CONNECTOME_${ID}_Weight_MeanFA_NumStreamlines_${NUMSTREAMS}.csv ${TEMPDIR}/CONNECTOME_FA.npy

# Get graph measure
python /APPS/scilpy/getgraphmeasures.py  ${TEMPDIR}/CONNECTOME_NUMSTREAM.npy ${TEMPDIR}/CONNECTOME_LENGTH.npy  ${TEMPDIR}/graphmeasures.json --avg_node_wise
python /APPS/scilpy/getgraphmeasures.py  ${TEMPDIR}/CONNECTOME_NUMSTREAM.npy ${TEMPDIR}/CONNECTOME_LENGTH.npy  ${TEMPDIR}/graphmeasures_nodes.json
# Compress tractogram, save
python /APPS/scilpy/scil_compress_streamlines.py ${TCK_FILE} ${TEMPDIR}/tracks_${NUMSTREAMS}_compressed.tck

# save outputs to output folder
cp ${TEMPDIR}/CONNECTOME* ${TEMPDIR}/tracks_${NUMSTREAMS}_compressed.tck ${TEMPDIR}/graphmeasures.json ${ATLAS} ${TEMPDIR}/graphmeasures_nodes.json  ${OUTPUTDIR}
