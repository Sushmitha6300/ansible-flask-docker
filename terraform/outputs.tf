output "controller_public_ip" {
  value = aws_instance.ansible_controller.public_ip
}

output "target_node_public_ip" {
  value = aws_instance.target_node.public_ip
}

output "target_node_private_ip" {
  value = aws_instance.target_node.private_ip
}