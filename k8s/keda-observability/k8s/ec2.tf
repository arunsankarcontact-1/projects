resource "aws_instance" "k8s_master" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.small"

  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  key_name               = aws_key_pair.k8s_key.key_name

  user_data = file("userdata-master.sh")

  tags = {
    Name = "k8s-master"
  }
}

resource "aws_instance" "k8s_worker" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.small"

  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  key_name               = aws_key_pair.k8s_key.key_name

  user_data = templatefile("userdata-worker.sh", {
    master_ip = aws_instance.k8s_master.private_ip
  })

  depends_on = [aws_instance.k8s_master]

  tags = {
    Name = "k8s-worker"
  }
}
