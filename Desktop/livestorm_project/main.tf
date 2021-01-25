# Create an EC2 instane
locals {
  vpc_id = "vpc-7e8da117"
  subnet_id = "subnet-18094371"
  ssh_user = "dimmy"
  key_name = "my_new_key"
  private_key_path = "~/livestorm_project/terraform/my_new_key.pem" 
}

provider "aws" {
  region  = "${var.region}"
  shared_credentials_file = "/c/Users/Dimmy/.aws/credentials"
}

resource "aws_instance" "nginx" {
  instance_type = "${var.instance_type}"
  ami = "${var.ami}"
  subnet_id = "subnet-18094371" 
  associate_public_ip_address = true 
  security_groups = [aws_security_group.nginx.id]
  key_name = local.key_name
  tags = {
      Name = "${var.tag}"
  }
  provisioner "remote-exec" {
    inline = ["echo 'wait for ssh to become ready'"]
    
    connection {
      type = "ssh"
      user = "local.ssh_user"
      private_key = file(local.private_key_path)
      host =  aws_instance.nginx.public_ip
    }
  }
  provisioner "local-exec" {
    command = "ansible-playbook -i ${aws_instance.nginx.public_ip},  --private-key ${local.private_key_path} nginx.yml"
  }
}  

output "nginx_ip" {
  value = aws_instance.nginx.public_ip
}


resource "aws_security_group" "nginx" {
  name = "nginx_access"
  vpc_id = local.vpc_id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks =  ["0.0.0.0/0"]
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks =  ["0.0.0.0/0"]
  }
  
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks =  ["0.0.0.0/0"]
  }
}
