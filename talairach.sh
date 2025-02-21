# Set your subject list file
subj_list=/projectnb/nickar/freesurfer_zekem/pdproject/newdirectory.txt

# Loop and submit to the batch system using the recon-all.qsub file.
count=$(cat $subj_list | wc -l)
for (( i=1; i<=$count; i++ ));
do
    subjid=$(cat $subj_list | head -$i | tail -1 | awk '{print $1}')
    label=$(cat $subj_list | head -$i | tail -1 | awk '{print $3}')
    qsub talairach.qsub $subjid $label
done