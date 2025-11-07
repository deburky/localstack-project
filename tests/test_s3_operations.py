import pytest
from src.examples.s3_operations import get_s3_client, create_bucket, upload_file

@pytest.fixture
def s3_client():
    return get_s3_client()

def test_create_bucket(s3_client):
    bucket_name = "test-bucket"
    create_bucket(bucket_name)
    response = s3_client.list_buckets()
    buckets = [bucket['Name'] for bucket in response['Buckets']]
    assert bucket_name in buckets

def test_upload_file(s3_client):
    bucket_name = "test-bucket-2"
    file_name = "test.txt"
    content = "Hello LocalStack!"
    
    create_bucket(bucket_name)
    upload_file(bucket_name, file_name, content)
    
    response = s3_client.get_object(Bucket=bucket_name, Key=file_name)
    assert response['Body'].read().decode() == content