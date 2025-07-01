variable "aws_region" { 
description = "La región de AWS donde se desplegará la 
infraestructura." 
type = string        
default = "us-east-1" # Puedes cambiarla a tu región preferida 
} 
 
variable "project_name" { 
  description = "Nombre del proyecto para etiquetar recursos." 
  type        = string 
  default     = "MiApp" 
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
  description = "ID de la AMI (Amazon Machine Image) para las 
instancias." 
  type        = string 
  # Puedes buscar la AMI más reciente para Ubuntu 22.04 LTS por 
ejemplo 
  # Visita https://cloud-images.ubuntu.com/locator/ec2/ para encontrar 
una AMI 
  default = "ami-053b0d53c2792add8" # Ejemplo para Ubuntu Server 22.04 
LTS en us-east-1 (N. Virginia) 
} 
 
variable "key_pair_name" { 
  description = "Nombre del par de claves SSH existente en AWS." 
  type        = string 
  # Asegúrate de tener un par de claves SSH en AWS, por ejemplo, 
"my-key-pair"
}