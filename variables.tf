variable "aws_region" { 
description = "Ohio"
type = string        
default = "us-east-2" # Puedes cambiarla a tu región preferida 
} 
 
variable "project_name" { 
  description = "Secretos para contar" 
  type        = string 
  default     = "secretos-para-contar-cloud7" 
} 
 
variable "vpc_cidr_block" { 
  description = "Bloque CIDR para la VPC." 
  type        = string 
  default     = "10.0.0.0/16" 
} 
 
variable "public_subnet_cidr_block" { 
  description = "Bloque CIDR para la subred pública." 
  type        = string 
  default     = "10.0.1.0/24" 
} 
 
variable "instance_type_frontend" { 
  description = "Tipo de instancia EC2 para el frontend." 
  type        = string 
  default     = "t2.micro" # Ajusta según tus necesidades 
} 
 
variable "instance_type_backend" { 
  description = "Tipo de instancia EC2 para el backend." 
  type        = string 
  default     = "t2.micro" # Ajusta según tus necesidades 
} 
 
variable "ami_id" { 
  description = "ID de la AMI (Amazon Machine Image) para las instancias." 
  type        = string 
  default = "ami-0c803b171269e2d72" 
} 
 
variable "key_pair_name" { 
  description = "Key pair para Cloud7 en AWS." 
  type        = string 
  default = "Cloud7"
}