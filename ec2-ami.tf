
data "aws_ami" "redhat" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["RHEL-9.2.0_HVM-*-GP2"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

output "redhat_ami_id_in_this_region" {
  value = data.aws_ami.redhat.image_id
}

