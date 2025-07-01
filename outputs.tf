# outputs.tf 
 
output "frontend_public_ip" { 
  description = "La IP pública de la instancia de frontend." 
  value       = aws_instance.frontend_instance.public_ip 
} 
 
output "backend_public_ip" { 
  description = "La IP pública de la instancia de backend." 
  value       = aws_instance.backend_instance.public_ip 
} 
 
output "frontend_public_dns" { 
description = "El DNS público de la instancia de frontend." 
value       
= aws_instance.frontend_instance.public_dns 
} 
output "backend_public_dns" { 
description = "El DNS público de la instancia de backend." 
value       
= aws_instance.backend_instance.public_dns 
} 