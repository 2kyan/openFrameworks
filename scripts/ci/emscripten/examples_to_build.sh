#!/bin/bash

# List of folder paths to iterate through make sure there is no trailing slash
folders=(
    "examples/3d/pointCloudExample"
    "examples/3d/3DPrimitivesExample"
#    "examples/3d/ofxAssimpBoneControlExample"
#    "examples/3d/ofxAssimpAdvancedExample"
    # Add more paths as needed
)

#echo "RUNNING IN CI ${GH_BRANCH} ${GH_ACTIONS}"
#echo "TRYING USER/SERVER ${GA_EXAMPLES_USER}@${GA_EXAMPLES_SERVER}" 

cur_root=$(pwd);
cd $cur_root;
mkdir -p out
out_folder="$cur_root/out"

# Iterate through the folder paths
for folder in "${folders[@]}"; do
    # Check if the folder exists
    if [ -d "$folder" ]; then

        # Change to the directory
        cd $folder
        cp ../../../scripts/templates/emscripten/Makefile .
		cp ../../../scripts/templates/emscripten/config.make .
        emmake make -j2 Release
        
        errorcode=$?
		if [[ $errorcode -ne 0 ]]; then
			echo "Couldn't build emscripten example: $folder"
		else
			folder_name=$(basename "$folder")
			cp -r "bin/em/$folder_name" "$out_folder/"
		fi
		
		cd $cur_root
    else
        echo "Folder does not exist: $folder"
    fi
done

cd $cur_root;
DO_UPLOAD="false"

#if [[ "$GH_ACTIONS" = true && "${GH_BRANCH}" == "master" && -z "${GH_HEAD_REF}" ]]; then
if [[ "$GH_ACTIONS" = "true" ]]; then
	echo "upload 1/2 - make key file"
    # Temporary file to store the private key
	key_file=$(mktemp)
	echo -e "$GA_EXAMPLES_KEY" > "$key_file"
	chmod 600 "$key_file"
    DO_UPLOAD="true";
fi

if [ "$DO_UPLOAD" = "true" ]; then
	echo "upload 2/2 - time for rsync"
	remote_path="/home/$GA_EXAMPLES_USER/examples/"
	rsync -avz -e "ssh -o 'StrictHostKeyChecking no' -i $key_file" "$out_folder/" "$GA_EXAMPLES_USER@$GA_EXAMPLES_SERVER:$remote_path"
    rm -f "$key_file"
fi