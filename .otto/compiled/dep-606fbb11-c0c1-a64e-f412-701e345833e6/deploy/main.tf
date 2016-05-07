# Generated by Otto, do not edit manually

variable "infra_id" {}
variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_region" {}
variable "key_name" {}

variable "ami" { default = "ami-21630d44" }
variable "instance_type" { default = "t2.micro" }
variable "subnet_public" {}
variable "vpc_cidr" {}
variable "vpc_id" {}

provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}

resource "aws_security_group" "app" {
  name   = "postgresql-${var.infra_id}"
  vpc_id = "${var.vpc_id}"

  ingress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Deploy a set of instances
resource "aws_instance" "app" {
  ami           = "${var.ami}"
  instance_type = "${var.instance_type}"
  subnet_id     = "${var.subnet_public}"
  key_name      = "${var.key_name}"
  user_data     = "${file("${path.module}/cloud-init.sh")}"

  vpc_security_group_ids = ["${aws_security_group.app.id}"]

  tags {
    Name = "postgresql"
  }

  connection {
    user         = "ubuntu"
    host         = "${self.public_ip}"
  }

  # Wait for cloud-init (ensures instance is fully booted before moving on)
  provisioner "remote-exec" {
    inline = ["while sudo pkill -0 cloud-init 2>/dev/null; do sleep 2; done"]
  }

  
  # Foundation 1 (build)
  provisioner "remote-exec" {
    inline = ["mkdir -p /tmp/otto/foundation-1"]
  }

  provisioner "file" {
    source = "/Users/thiago/Projects/Ruby/rails-otto/.otto/compiled/dep-606fbb11-c0c1-a64e-f412-701e345833e6/foundation-consul/app-build/"
    destination = "/tmp/otto/foundation-1"
  }

  provisioner "remote-exec" {
    inline = ["cd /tmp/otto/foundation-1 && bash ./main.sh"]
  }
  

  
  # Foundation 1 (deploy)
  provisioner "remote-exec" {
    inline = ["mkdir -p /tmp/otto/foundation-deploy-1"]
  }

  provisioner "file" {
    source = "/Users/thiago/Projects/Ruby/rails-otto/.otto/compiled/dep-606fbb11-c0c1-a64e-f412-701e345833e6/foundation-consul/app-deploy/"
    destination = "/tmp/otto/foundation-deploy-1"
  }

  provisioner "remote-exec" {
    inline = ["cd /tmp/otto/foundation-deploy-1 && bash ./main.sh"]
  }
  

  # Remove any temporary directories we made from foundations (if any)
  provisioner "remote-exec" {
    inline = ["rm -rf /tmp/otto"]
  }
}

output "ip" {
  value = "${aws_instance.app.public_ip}"
}
