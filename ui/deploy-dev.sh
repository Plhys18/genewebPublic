#!/bin/bash

# specify the remote server address
remote_server=golemdevncbrmuni@golem-dev.ncbr.muni.cz

# specify the path to the custom key
key_file=~/.ssh/id_rsa_golemdev

# Port for SSH
port=22

# BEWARE OF DIFFERENT DIR TO SOURCE DATASETS DEV vs PROD

# Check if the --with-datasets argument was passed
if [[ "$1" == "--with-datasets" ]]; then
    echo "Copying datasets..."
    scp -P $port -i $key_file -r ../datasets/upload-dev/. $remote_server:~/public_datasets/
fi

# build
echo "Running build..."
flutter build web --release --web-renderer canvaskit --pwa-strategy none
if [ $? -ne 0 ]; then
    echo "Error: Flutter build failed."
    exit 1
fi

echo "Deploying..."
# delete the existing files on the remote server
ssh -i $key_file -p $port $remote_server "rm -rf ~/public_html/*"
if [ $? -ne 0 ]; then
    echo "Error: Failed to connect."
    exit 1
fi

# create symlink to datasets
ssh -i $key_file -p $port $remote_server "cd public_html && ln -s ../public_datasets datasets"
if [ $? -ne 0 ]; then
    echo "Error: Failed to create the symlink to datasets."
    exit 1
fi


# copy the contents of the local build directory to the remote server
scp -P $port -i $key_file -r build/web/. $remote_server:~/public_html/
if [ $? -ne 0 ]; then
    echo "Error: Failed to copy files."
    exit 1
fi

# print a success message
echo "Deployment completed successfully!"
echo "https://golem-dev.ncbr.muni.cz/"