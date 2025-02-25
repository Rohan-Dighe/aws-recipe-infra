import boto3
import zipfile
import os
import urllib.parse

s3 = boto3.client('s3')

def lambda_handler(event, context):
    source_bucket = event['Records'][0]['s3']['bucket']['name']
    object_key = event['Records'][0]['s3']['object']['key']
    
    #  Decode the object key in case of spaces or special characters
    object_key = urllib.parse.unquote_plus(object_key)

    print(f" Source Bucket: {source_bucket}")
    print(f" Object Key: {object_key}")

    destination_bucket = os.environ['OUTPUT_BUCKET']
    zip_file = "/tmp/recipes.zip"
    local_file = f"/tmp/{object_key}"

    try:
        print(" Checking if object exists in S3...")
        s3.head_object(Bucket=source_bucket, Key=object_key)  #  This will check if the file exists

        print(" Downloading file from S3...")
        s3.download_file(source_bucket, object_key, local_file)
    except Exception as e:
        print(f" Error: {str(e)}")  #  Log the actual error
        return {"statusCode": 500, "body": f"Error downloading file: {str(e)}"}

    print(" Creating ZIP file...")
    with zipfile.ZipFile(zip_file, 'w') as zipf:
        zipf.write(local_file, arcname=object_key)

    print(" Uploading ZIP file to archive bucket...")
    s3.upload_file(zip_file, destination_bucket, "recipes.zip")

    return {"statusCode": 200, "body": "Zipped and uploaded successfully"}
