import os
import boto3
from dotenv import load_dotenv

load_dotenv()


def get_s3_client():
    return boto3.client(
        "s3",
        endpoint_url=os.getenv("ENDPOINT_URL"),
        aws_access_key_id=os.getenv("AWS_ACCESS_KEY_ID"),
        aws_secret_access_key=os.getenv("AWS_SECRET_ACCESS_KEY"),
        region_name=os.getenv("AWS_DEFAULT_REGION"),
    )


def create_bucket(bucket_name):
    s3 = get_s3_client()
    s3.create_bucket(Bucket=bucket_name)
    print(f"Created bucket: {bucket_name}")


def list_buckets():
    s3 = get_s3_client()
    response = s3.list_buckets()
    print("Existing buckets:")
    for bucket in response["Buckets"]:
        print(f"  {bucket['Name']}")


def upload_file(bucket_name, file_name, content):
    s3 = get_s3_client()
    s3.put_object(Bucket=bucket_name, Key=file_name, Body=content)
    print(f"Uploaded {file_name} to {bucket_name}")


if __name__ == "__main__":
    # Example usage
    bucket_name = "test-bucket"
    create_bucket(bucket_name)
    list_buckets()
    upload_file(bucket_name, "test.txt", "Hello LocalStack!")
