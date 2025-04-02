# EC2 Instances

# Generates a secure private key and encodes it as PEM
resource "tls_private_key" "key_pair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
# Create the Key Pair
resource "aws_key_pair" "key_pair" {
  key_name   = "${data.aws_region.current_region.name}-terraform-key"
  public_key = tls_private_key.key_pair.public_key_openssh
}
# Save file
resource "local_file" "ssh_key" {
  filename        = "${aws_key_pair.key_pair.key_name}.pem"
  content         = tls_private_key.key_pair.private_key_pem
  file_permission = "0400"

  provisioner "local-exec" {
    command = "ssh-add -k ${path.module}/${aws_key_pair.key_pair.key_name}.pem"
  }
}

# Create 2 separate ec2 instances, one for db_server and the other for the web_server
resource "aws_instance" "db_server" {
  ami                         = data.aws_ami.redhat.id
  instance_type               = data.aws_region.current_region.name == "eu-north-1" ? "t3.micro" : "t2.micro" # var.instance_type
  key_name                    = aws_key_pair.key_pair.key_name
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.grad_proj_sg["ssh"].id, aws_security_group.grad_proj_sg["http_https"].id, aws_security_group.grad_proj_sg["public"].id] #vpc_security_group_ids      = [ aws_security_group.http-only.id, aws_security_group.ssh-only.id ]
  source_dest_check           = true
  credit_specification {
    cpu_credits = "standard" #As T3 instances are launched as unlimited by default. T2 instances are launched as standard by default
  }

  # root disk  
  root_block_device {
    volume_size           = 10
    volume_type           = "gp2"
    encrypted             = false
    delete_on_termination = true
  }

  tags = {
    "Name" = "db-server"
  }
}

resource "null_resource" "configure_html_files" {
  provisioner "local-exec" {
    command = "export dburl=${aws_instance.db_server.public_ip} ; envsubst '$dburl' < ./redhat/html_files/addcontact-vars > ./redhat/html_files/addcontact.php ; envsubst '$dburl' < ./redhat/html_files/print_users-vars > ./redhat/html_files/print_users.php ; sleep 120 ; ansible-playbook --inventory ${aws_instance.db_server.public_ip}, --user ec2-user  ./redhat/deploy_mysql_server.yaml"
  }
  depends_on = [aws_instance.db_server]
}

resource "aws_instance" "httpd_server" {
  depends_on                  = [null_resource.configure_html_files]
  ami                         = data.aws_ami.redhat.id
  instance_type               = data.aws_region.current_region.name == "eu-north-1" ? "t3.micro" : "t2.micro"
  key_name                    = aws_key_pair.key_pair.key_name
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.grad_proj_sg["ssh"].id, aws_security_group.grad_proj_sg["http_https"].id, aws_security_group.grad_proj_sg["public"].id]
  source_dest_check           = true
  credit_specification {
    cpu_credits = "standard" #As T3 instances are launched as unlimited by default. T2 instances are launched as standard by default
  }

  # root disk  
  root_block_device {
    volume_size           = 10
    volume_type           = "gp2"
    encrypted             = false
    delete_on_termination = true
  }

  tags = {
    "Name" = "httpd-server"
  }

  provisioner "local-exec" {
    working_dir = "./"
    command     = "sleep 100 ; ansible-playbook --inventory ${aws_instance.httpd_server.public_ip}, --user ec2-user  ./redhat/deploy_httpd.yaml"
  }
}


output "the_puboic_IP_of_the_db_server_instance" {
  value = aws_instance.db_server.public_ip
}

output "the_dns_of_the_web_server___just_copy_it_in_the_browser" {
  value = aws_instance.httpd_server.public_dns
}