Directory Structure :

terraform-3tier/
├── main.tf
├── variables.tf
├── outputs.tf
├── provider.tf
├── backend.tf
├── modules/
│   ├── network/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── web/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── app/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── db/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf


Terraform - AWS configuration :

1. Create an EC2 Instance (Terraform Server)
    Login to your AWS Console → go to EC2 service.
    Click Launch Instance.
    Fill in details:
    Name: Terraform-Server
    AMI: Choose Amazon Linux 2 (64-bit x86).
    Instance type: t2.micro (Free Tier) or t3.micro.
    Key pair: Create a new key pair → download the .pem file (keep it safe!).
    Network settings:
    Allow SSH traffic from your IP.
    Everything else can stay default.
    Storage: 20 GB (recommended).
    Click Launch Instance.
    Wait 1–2 minutes until the instance is running.
2. Connect to the EC2 Instance (I used AWS connect service)
    ✅ Find Public IP: Go to your EC2 dashboard → Click your instance → Copy Public IPv4 address.
    ✅ Open your local terminal:
    If you are using Windows → open PowerShell.
    If you are on Mac/Linux → open Terminal.
    Run this (replace your key file name and IP):
    ssh -i "your-key.pem" ec2-user@your-public-ip
3. sudo yum update -y : This updates all existing packages.
   sudo yum install -y git unzip wget : install a few basic tools
4. Install AWS CLI (so Terraform can talk to AWS)
    cd /tmp
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    aws --version
5. Install Terraform
    cd /tmp
    sudo yum install -y unzip
    curl -O https://releases.hashicorp.com/terraform/1.6.6/terraform_1.6.6_linux_amd64.zip (install latest version)
    unzip terraform_1.6.6_linux_amd64.zip
    sudo mv terraform /usr/local/bin/
    terraform version
6. Configure AWS Credentials
    Attach IAM Role to EC2
    If you know IAM:
    Create an IAM role with policy AmazonEC2FullAccess.
    Attach that IAM role to your EC2 Terraform server.
    Terraform will automatically use it.


Setting up S3 + DynamoDB remote backend for Terraform state (to store your state file safely) : 


1. Create S3 Bucket for Terraform State (Attach role with permission AmazonS3fullaccess to Terraform server)
    AWS_REGION=ap-south-1   # or your preferred region
    BUCKET_NAME=my-terraform-state-ayushi   # must be globally unique
    -Create bucket
    aws s3api create-bucket \
      --bucket $BUCKET_NAME \
      --region $AWS_REGION \
      --create-bucket-configuration LocationConstraint=$AWS_REGION
    -Enable versioning (important for rollback safety)
    aws s3api put-bucket-versioning \
      --bucket $BUCKET_NAME \
      --versioning-configuration Status=Enabled
    -Enable encryption
    aws s3api put-bucket-encryption \
      --bucket $BUCKET_NAME \
      --server-side-encryption-configuration '{
        "Rules": [{
          "ApplyServerSideEncryptionByDefault": {
            "SSEAlgorithm": "AES256"
          }
        }]
      }'

   check : aws s3 ls
   2. Create DynamoDB Table for State Locking (Attach role with permission AmazonDynamoDBFullAccess to Terraform server)
       TABLE_NAME=terraform-locks
       aws dynamodb create-table \
        --table-name $TABLE_NAME \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
        --region $AWS_REGION

      check : aws dynamodb list-tables --region $AWS_REGION




terraform-github-actions CICD configuration :

1. Create AWS credentials for GitHub
    In the AWS Console → IAM → Users → Add user, create a CI user like:
    terraform-github-actions
    Attach the following policies:
    AmazonS3FullAccess
    AmazonDynamoDBFullAccess
    AmazonEC2FullAccess
    AmazonRDSFullAccess
    IAMFullAccess (optional, if Terraform manages roles)
    Then go to the Security Credentials tab → Create Access Key.
    You'll get Access key & Secret key.

2. Store these secrets in GitHub
    Go to your repo →
    Settings → Secrets and Variables → Actions → New Repository Secret
    Add:
    Name	Value
    AWS_ACCESS_KEY_ID	(your key ID)
    AWS_SECRET_ACCESS_KEY	(your secret)
    AWS_REGION	us-east-1
    ✅ These will be injected into the GitHub Actions environment automatically.

3. Add the GitHub Actions workflow
    Create a new folder and file in your repo:
    .github/workflows/terraform.yml

4. What each step does
    Step	                    Purpose
    actions/checkout	        Downloads your repo code into the runner
    hashicorp/setup-terraform	Installs the specified Terraform version
    configure-aws-credentials	Authenticates to AWS using repo secrets
    terraform init	            Connects to your backend (S3 + DynamoDB)
    terraform validate	        Checks configuration syntax
    terraform plan	            Creates an execution plan
    terraform apply	            Builds or updates infra (only on main branch)

5. Verify the pipeline
    1. Commit & push:
        git add .github/workflows/terraform.yml
        git commit -m "Add Terraform CI/CD workflow"
        git push origin main
    2. Go to GitHub → Actions tab
        You’ll see the pipeline running.
        It will:
        Initialize Terraform
        Validate
        Plan
        Apply (if on main)

✅ Final Result
    Whenever you push Terraform changes to main:
    GitHub Actions runs automatically
    Your backend state stays in Amazon S3
    Locking is handled by Amazon DynamoDB
    Infrastructure changes are deployed securely and consistently