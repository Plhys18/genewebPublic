#!/bin/bash

# specify the remote server address
remote_server=genewebncbrmuni@147.251.6.69

# specify the path to the custom key
key_file=~/.ssh/id_rsa_geneweb

# build
echo "Running build..."
flutter build web --release
if [ $? -ne 0 ]; then
    echo "Error: Flutter build failed."
    exit 1
fi

echo "Deploying..."
# delete the existing files on the remote server
ssh -i $key_file $remote_server "rm -rf ~/public_html/*"
if [ $? -ne 0 ]; then
    echo "Error: Failed to connect."
    exit 1
fi

# copy the contents of the local build directory to the remote server
scp -i $key_file -r build/web/. $remote_server:~/public_html/
if [ $? -ne 0 ]; then
    echo "Error: Failed to copy files."
    exit 1
fi

# print a success message
echo "Deployment completed successfully!"
echo "http://geneweb-ncbr-muni-cz.demo.web01.ics.muni.cz/"