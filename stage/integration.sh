#!/bin/sh

# This script checks that the file file_name exists:
# 0. First, that it does not exist in the bucket before the migration
# neither in the the mounted share in the application server
# 1. in the bucket after the datasync task is executed
# 2. in the mounted share in teh application server

aws s3 ls s3://core-bucket-tf | grep "hola"
aws datasync start-task-execution     --task-arn $(terraform output -raw datasync-task-id)

# while
  #
  #aws datasync describe-task-execution \
  #    --task-execution-arn $(terrafo
  #rm output -raw datasync-task-id)
  #
  #.Status = Sucess