output "splunk_public_ip" {
    description = "Public IP of Splunk - access UI at http://<ip>:8000"
    value       = aws_instance.splunk.public_ip
}

output "splunk_private_ip" {
    description = "Private IP of Splunk — use this when configuring the Splunk forwarder on Windows"
    value       = aws_instance.splunk.private_ip 
}

output "windows_victim_public_ip" {
    description = "Public IP of Windows victim — RDP to this address"
    value       = aws_instance.windows_victim.public_ip
}

output "kali_attacker_public_ip" {
    description = "Public IP of Kali — SSH with: ssh -i your-key.pem kali@<ip>"
    value       = aws_instance.kali_attacker.public_ip
}