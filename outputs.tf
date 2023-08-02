# Adding an output config that will extract the load balancer URL value 
#from the state file and log it onto the terminal
#Log the load balancer app URL
output "app_url" {
  value = aws_alb.application_lb.dns_name
}