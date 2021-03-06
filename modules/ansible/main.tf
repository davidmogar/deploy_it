resource "random_uuid" "inventory_name" {}

resource "local_file" "inventory" {
  file_permission = "0440"
  filename        = "ansible/inventories/${random_uuid.inventory_name.result}"

  content = <<-EOF
[all:vars]
ansible_user=${var.ssh_user}
ansible_ssh_common_args="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand='ssh -i ${var.bastion_ssh_key_path} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -W %h:%p ${var.ssh_user}@${var.bastion}'"
ansible_ssh_private_key_file=${var.ssh_key_path}

[all]
${var.host}
    EOF
}

resource "null_resource" "provisioner" {
  depends_on = [local_file.inventory]

  provisioner "remote-exec" {
    connection {
      bastion_host        = var.bastion
      bastion_private_key = file(var.bastion_ssh_key_path)
      host                = var.host
      private_key         = file(var.ssh_key_path)
      type                = "ssh"
      user                = var.ssh_user
    }
  }

  provisioner "local-exec" {
    command = "ansible-playbook -i ansible/inventories/${random_uuid.inventory_name.result} ${join(" ", compact(var.extra_arguments))} ${var.playbook}"
  }
}
