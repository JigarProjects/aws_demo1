# Security Group for Bastion Host
resource "aws_security_group" "bastion" {
    name        = "bastion"
    description = "Allow SSH and Session Manager access to bastion host"
    vpc_id      = aws_vpc.vpc01.id

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "bastion"
    }
}

# IAM Role for Session Manager
resource "aws_iam_role" "ssm_role" {
    name = "ssm-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Principal = {
                    Service = "ec2.amazonaws.com"
                }
            }
        ]
    })
}

# -- Attach SSM policy to the role
resource "aws_iam_role_policy_attachment" "ssm_policy" {
    role       = aws_iam_role.ssm_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# -- Instance Profile for SSM
resource "aws_iam_instance_profile" "ssm_profile" {
    name = "ssm-profile"
    role = aws_iam_role.ssm_role.name
}

# -- Bastion Host EC2 Instance
resource "aws_instance" "bastion" {
    ami                    = "ami-07a6f770277670015" # Amazon Linux 2
    instance_type          = "t2.micro"
    subnet_id              = aws_subnet.vpc01_public[0].id
    vpc_security_group_ids = [aws_security_group.bastion.id]
    iam_instance_profile   = aws_iam_instance_profile.ssm_profile.name

    tags = {
        Name = "bastion-host"
    }

    # Install SSM Agent, MySQL client and cloudwatch agent to get disk related info
    user_data = <<-EOF
        #!/bin/bash
        sudo yum update -y
        sudo yum install -y mysql
        sudo systemctl enable amazon-ssm-agent
        sudo systemctl start amazon-ssm-agent
        sudo yum install -y amazon-cloudwatch-agent
    EOF
}

# Output bastion host private IP
output "bastion_private_ip" {
    value = aws_instance.bastion.private_ip
}

# Output bastion host public IP
output "bastion_public_ip" {
    value = aws_instance.bastion.public_ip
}
