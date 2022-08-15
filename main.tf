# Extracts AWS AMI id from AWS which is type Amazon linux-2 with provided filters.
data "aws_ami" "amazon-linux-2" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  owners = ["amazon"] # Canonical
}

# Template file renders a template by referencing to an outside script/file to take care of user_data/bootstrapping.
data "template_file" "userdata" {
  template = file("${abspath(path.module)}/userdata.sh")
  vars = {
    server-name = var.server-name
  }
}

# Creates Ec2 with provided userdata.sh scipt file.
resource "aws_instance" "tfmyec2" {
  ami                    = data.aws_ami.amazon-linux-2.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.tf-sec-gr.id]
  count                  = var.num_of_instance
  user_data              = data.template_file.userdata.rendered

  tags = {
    Name = var.tag
  }
}

resource "aws_security_group" "tf-sec-gr" {
  name = "${var.tag}-terraform-sec-grp"

  dynamic "ingress" {
    for_each = var.docker-instance-ports
    iterator = port
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.tag
  }
}