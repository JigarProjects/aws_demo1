# Security Group for Bastion Host
resource "aws_security_group" "bastion_vpc02" {
    name        = "bastion-vpc02"
    description = "Allow SSH and Session Manager access to bastion host"
    vpc_id      = aws_vpc.vpc02.id

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
        Name = "bastion-vpc02"
    }
}

# IAM Role for Session Manager
resource "aws_iam_role" "ssm_role_vpc02" {
    name = "ssm-role-vpc02"

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

# Attach SSM policy to the role
resource "aws_iam_role_policy_attachment" "ssm_policy_vpc02" {
    role       = aws_iam_role.ssm_role_vpc02.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance Profile for SSM
resource "aws_iam_instance_profile" "ssm_profile_vpc02" {
    name = "ssm-profile-vpc02"
    role = aws_iam_role.ssm_role_vpc02.name
}

# Bastion Host EC2 Instance
resource "aws_instance" "bastion_vpc02" {
    ami                    = "ami-07a6f770277670015" # Amazon Linux 2
    instance_type          = "t2.micro"
    subnet_id              = aws_subnet.vpc02_public[0].id
    vpc_security_group_ids = [aws_security_group.bastion_vpc02.id]
    iam_instance_profile   = aws_iam_instance_profile.ssm_profile_vpc02.name

    tags = {
        Name = "bastion-vpc02"
    }

    # Install SSM Agent and MySQL client
    user_data = <<-EOF
        #!/bin/bash
        sudo yum update -y
        sudo systemctl enable amazon-ssm-agent
        sudo systemctl start amazon-ssm-agent
    EOF
}

# Output bastion host private IP
output "bastion_vpc02_private_ip" {
    value = aws_instance.bastion_vpc02.private_ip
}
