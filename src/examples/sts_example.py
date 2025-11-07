import os
import json
import boto3
from dotenv import load_dotenv

load_dotenv()

def get_sts_client():
    return boto3.client('sts',
                       endpoint_url=os.getenv('ENDPOINT_URL'),
                       aws_access_key_id=os.getenv('AWS_ACCESS_KEY_ID'),
                       aws_secret_access_key=os.getenv('AWS_SECRET_ACCESS_KEY'),
                       region_name=os.getenv('AWS_DEFAULT_REGION'))

def assume_role():
    """
    Demonstrates assuming a role using STS
    """
    sts = get_sts_client()
    
    # Create an IAM client to create a role first
    iam = boto3.client('iam',
                      endpoint_url=os.getenv('ENDPOINT_URL'),
                      aws_access_key_id=os.getenv('AWS_ACCESS_KEY_ID'),
                      aws_secret_access_key=os.getenv('AWS_SECRET_ACCESS_KEY'),
                      region_name=os.getenv('AWS_DEFAULT_REGION'))
    
    # Create a role that trusts the current account
    trust_policy = {
        "Version": "2012-10-17",
        "Statement": [{
            "Effect": "Allow",
            "Principal": {"AWS": "arn:aws:iam::000000000000:root"},
            "Action": "sts:AssumeRole"
        }]
    }
    
    try:
        # Create the IAM role
        role = iam.create_role(
            RoleName='MLModelRole',
            AssumeRolePolicyDocument=json.dumps(trust_policy)
        )
        print(f"Created role: {role['Role']['Arn']}")
        
        # Assume the role
        assumed_role = sts.assume_role(
            RoleArn=role['Role']['Arn'],
            RoleSessionName='MLModelSession'
        )
        
        print("\nAssumed role credentials:")
        print(f"Access Key: {assumed_role['Credentials']['AccessKeyId']}")
        print(f"Secret Key: {assumed_role['Credentials']['SecretAccessKey']}")
        print(f"Session Token: {assumed_role['Credentials']['SessionToken']}")
        print(f"Expiration: {assumed_role['Credentials']['Expiration']}")
        
        return assumed_role['Credentials']
        
    except Exception as e:
        print(f"Error: {str(e)}")
        return None

if __name__ == "__main__":
    credentials = assume_role()
    if credentials:
        print("\nSuccessfully assumed role!")