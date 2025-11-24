resource "aws_security_group" "test-sg" {
  name        = "Allow SSH"
  description = "Allow SSH to login"
  vpc_id      = var.vpc_id

  tags = {
    Name = "allow_ssh"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv4" {
  security_group_id = aws_security_group.test-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

# EC2 instance creation.

resource "aws_instance" "test-server" {

  ami                    = data.aws_ami.amazon-linux.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = ["${aws_security_group.test-sg.id}"]
  tags = {
    Name     = var.tag
    shutdown = var.shutdown ? "true" : "false"
  }
}