# terraform {
#   required_providers {
#     null = {
#       source  = "hashicorp/null"
#       version = "3.2.3"
#     }
#     aws = {
#       source  = "hashicorp/aws"
#       version = "5.81.0"
#     }
#   }
# }
## policy banana hai
resource "aws_iam_policy" "policy1" {
  name        = "${var.component}-${var.env}-ssm-parameter-policy"
  path        = "/"
  description = "${var.component}-${var.env}-ssm-parameter-policy to fetch the parameters"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "VisualEditor0",
        "Effect": "Allow",
        "Action": [
          "ssm:GetParameterHistory",
          "ssm:GetParametersByPath",
          "ssm:GetParameters",
          "ssm:GetParameter"
        ],
        "Resource": "arn:aws:ssm:us-east-1:275396904943:parameter/roboshop.${var.env}.${var.component}.*"
      }
    ]
  })
}

## Iam role ko attach karna hai policy se

resource "aws_iam_role" "role1" {
  name = "${var.component}-${var.env}-EC2-role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  })
}

## attach policy to a role

resource "aws_iam_role_policy_attachment" "policy-attach" {
  policy_arn = aws_iam_role.role1.name
  role       = aws_iam_policy.policy1.arn
}
## instance profile for ec2 attachment

resource "aws_iam_instance_profile" "instance_profile" {
  name = "${var.component}-${var.env}-test-profile"
  role = aws_iam_role.role1.name
}


## security group banana hai
resource "aws_security_group" "sg" {
  name = "${var.component}-${var.env}-sg"
  description = "${var.component}-${var.env}-sg Allow TLS inbound traffic"

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }
  tags = {
    Name = "${var.component}-${var.env}-sg"
  }
}


##ec2

resource "aws_instance" "web" {

  ami = data.aws_ami.centos8.id
  instance_type = "t3.small"
  vpc_security_group_ids = [aws_security_group.sg.id]
  iam_instance_profile = aws_iam_instance_profile.instance_profile.name

  tags = {
    Name = "${var.component}-${var.env}"
  }

}


##DNS record route 53 ke liye
resource "aws_route53_record" "dns_record" {
  zone_id = "Z0465086RMHEURU6S6M8"
  name = "${var.component}-${var.env}"
  type = "A"
  ttl = 30
  records = [aws_instance.web.private_ip]
}



##null resource to run ansible
resource "null_resource" "ansible_tasks" {

  depends_on = [aws_instance.web , aws_route53_record.dns_record]
  provisioner "remote-exec" {

    connection {
      type = "ssh"
      user = "centos"
      password = "DevOps321"
      host = aws_instance.web.public_ip
    }
    inline = [

      "sudo labauto ansible",
      "ansible-pull -i localhost, -U https://github.com/priyanshuprafful/roboshop-ansible-2.0 main.yml -e env=${var.env} -e role_name=${var.component}"

    ]
  }
}

