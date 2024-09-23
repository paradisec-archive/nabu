#!/bin/bash

echo "$@"

if [ -z "$S3_BUCKET" ] || [ -z "$S3_KEY" ]; then
        echo "Error: S3_BUCKET and S3_KEY environment variables must be set"
        exit 1
fi

# Download file from S3 to /tmp
if ! aws s3 cp "s3://${S3_BUCKET}/${S3_KEY}" /tmp/downloaded_file; then
        echo "Error: Failed to download file from S3"
        exit 1
fi

# Process the downloaded file with MediaFlux script
/app/upload --dest "/projects/proj-1190_paradisec_backup-1128.4.248/TEST/$S3_KEY" --create-parents /tmp/downloaded_file

# Remove the downloaded file
rm /tmp/downloaded_file
