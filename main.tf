provider "aws" {
  profile = "lordkroft"
  region  = "us-east-2"
}


# Security Group
variable "ingressrules" {
  type    = list(number)
  default = [8080, 22]
}
resource "aws_security_group" "web_traffic" {
  name        = "Allow web traffic"
  description = "inbound ports for ssh and standard http and everything outbound"
  # dynamic "ingress" { #iterator = port
  #   for_each = var.ingressrules
    ingress{#content {
      from_port   = 0
      to_port     = 8080
      protocol    = "TCP"
      cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
    from_port               = 22
    to_port                 = 22
    protocol                = "tcp"
    }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    "Terraform" = "true"
  }
}



# Data Block
data "aws_ami" "redhat" {
  most_recent = true
  filter {
    name   = "name"
    values = ["RHEL-7.5_HVM_GA*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["309956199498"]
}




# resource block
resource "aws_instance" "jenkins" {
  ami             = data.aws_ami.redhat.id
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.web_traffic.name]
  key_name        = "app-demo-key"



provisioner "remote-exec"  {
    inline  = [
      "sudo yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm",
      "sudo yum install -y jenkins java-11-openjdk-devel",
      "sudo yum -y install wget",
      "sudo wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat-stable/jenkins.repo",
      "sudo rpm --import https://jenkins-ci.org/redhat/jenkins-ci.org.key",
      "sudo yum upgrade && update -y",
      "sudo yum install jenkins -y",
      "sudo systemctl start jenkins",
      ]
   }
 connection {
    type         = "ssh"
    host         = self.public_ip
    user         = "ec2-user"
    private_key  = "${file("/home/uladzimir/keys/app-demo-key.pem")}"
   }
  tags  = {
    "Name"      = "Jenkins"
      }
 }






