resource "aws_instance" "k8s" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.small"

  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  
  key_name = aws_key_pair.k8s_key.key_name

  user_data = file("userdata.sh")

  tags = {
    Name = "k8s-ingress-migration"
  }
}
