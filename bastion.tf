module "bastion" {
  source = "./modules/instance"

  ami = var.ami["ubuntu"]
  ingresses = [
    { "cidr_blocks" = ["0.0.0.0/0"], "port" = 22 }
  ]
  instance_type = var.instance
  description   = "Allow traffic to ssh port"
  name          = "bastion"
  subnet        = aws_subnet.public
  vpc           = aws_vpc.main
}

resource "null_resource" "bastion" {
  provisioner "remote-exec" {
    connection {
      host        = module.bastion.public_ip
      private_key = file(var.ssh_key_path)
      type        = "ssh"
      user        = var.ssh_user
    }

    inline = [
      "sudo cp /etc/ssh/ssh_host_rsa_key /home/ubuntu/.ssh/id_rsa",
      "sudo chown ubuntu:ubuntu /home/ubuntu/.ssh/id_rsa"
    ]
  }
}
