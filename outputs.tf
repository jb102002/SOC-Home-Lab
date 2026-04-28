# -----------------------------------------------
# OUTPUTS
# These values are printed in your terminal after
# "terraform apply" finishes. Use them to connect
# to your machines. Save these IPs — you'll need them.
# -----------------------------------------------

# Public IP to access the Splunk web UI from your browser
# Go to http://<this_ip>:8000 to log into Splunk
output "splunk_public_ip" {
    description = "Public IP of Splunk - access UI at http://<ip>:8000"
    value       = aws_instance.splunk.public_ip
}

# Private IP of Splunk — used INSIDE the lab network
# When configuring the Splunk Universal Forwarder on Windows,
# point it at this IP (not the public one) so traffic stays inside the VPC.
output "splunk_private_ip" {
    description = "Private IP of Splunk — use this when configuring the Splunk forwarder on Windows"
    value       = aws_instance.splunk.private_ip 
}

# Public IP of the Windows victim — use this to RDP in
# Open Remote Desktop and connect to this address
output "windows_victim_public_ip" {
    description = "Public IP of Windows victim — RDP to this address"
    value       = aws_instance.windows_victim.public_ip
}

# Public IP of Kali — use this to SSH in
# Run: ssh -i your-key.pem kali@<this_ip>
output "kali_attacker_public_ip" {
    description = "Public IP of Kali — SSH with: ssh -i your-key.pem kali@<ip>"
    value       = aws_instance.kali_attacker.public_ip
}