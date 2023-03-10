#!/bin/bash

# specify the remote server address
remote_server=genewebncbrmuni@147.251.6.69

# specify the path to the custom key
key_file=~/.ssh/id_rsa_geneweb

ssh -i $key_file $remote_server