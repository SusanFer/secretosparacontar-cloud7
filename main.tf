# --- Red (VPC) --- 
resource "aws_vpc" "main" { 
  cidr_block = var.vpc_cidr_block 
  enable_dns_hostnames = true 
 
  tags = { 
    Name = "${var.project_name}-VPC" 
  } 
} 
 
# --- Subred Pública --- 
resource "aws_subnet" "public" { 
  vpc_id                  = aws_vpc.main.id 
  cidr_block              = var.public_subnet_cidr_block 
  map_public_ip_on_launch = true # Para que las instancias obtengan 
una IP pública 
  availability_zone       = "${var.aws_region}a" # Puedes usar una 
zona de disponibilidad específica 
 
  tags = { 
    Name = "${var.project_name}-PublicSubnet" 
  } 
} 
 
# --- Internet Gateway (para salida a Internet) --- 
resource "aws_internet_gateway" "main" { 
  vpc_id = aws_vpc.main.id 
 
  tags = { 
    Name = "${var.project_name}-IGW" 
  } 
} 
 
# --- Tabla de Rutas Pública --- 
resource "aws_route_table" "public" { 
  vpc_id = aws_vpc.main.id 
 
  route { 
    cidr_block = "0.0.0.0/0" # Ruta por defecto a Internet 
    gateway_id = aws_internet_gateway.main.id 
  } 
 
  tags = { 
    Name = "${var.project_name}-PublicRouteTable" 
  } 
} 
 
# --- Asociación de la Tabla de Rutas a la Subred Pública --- 
resource "aws_route_table_association" "public" { 
  subnet_id      = aws_subnet.public.id 
  route_table_id = aws_route_table.public.id 
} 
 
# --- Grupos de Seguridad (Security Groups) --- 
 
# Grupo de Seguridad para el Frontend (permitir tráfico web) 
resource "aws_security_group" "frontend_sg" { 
  name        = "${var.project_name}-Frontend-SG" 
  description = "Permitir tráfico HTTP/HTTPS y SSH al frontend" 
  vpc_id      = aws_vpc.main.id 
 
  ingress { 
    description = "SSH desde cualquier lugar" 
    from_port   = 22 
    to_port     = 22 
    protocol    = "tcp" 
    cidr_blocks = ["0.0.0.0/0"] 
  } 
 
  ingress { 
    description = "HTTP desde cualquier lugar" 
    from_port   = 80 
    to_port     = 80 
    protocol    = "tcp" 
    cidr_blocks = ["0.0.0.0/0"] 
  } 
 
  ingress { 
    description = "HTTPS desde cualquier lugar" 
    from_port   = 443 
    to_port     = 443 
    protocol    = "tcp" 
    cidr_blocks = ["0.0.0.0/0"] 
  } 
 
  # Regla de egreso (salida) para permitir todo el tráfico saliente 
  egress { 
    from_port   = 0 
    to_port     = 0 
    protocol    = "-1" 
    cidr_blocks = ["0.0.0.0/0"] 
  } 
 
  tags = { 
    Name = "${var.project_name}-Frontend-SG" 
  } 
} 
 
# Grupo de Seguridad para el Backend (permitir tráfico desde el 
frontend y SSH) 
resource "aws_security_group" "backend_sg" { 
  name        = "${var.project_name}-Backend-SG" 
  description = "Permitir tráfico desde el frontend y SSH al backend" 
  vpc_id      = aws_vpc.main.id 
 
  ingress { 
    description = "SSH desde cualquier lugar" 
    from_port   = 22 
    to_port     = 22 
    protocol    = "tcp" 
    cidr_blocks = ["0.0.0.0/0"] # Considerar restringir esto a tu IP o 
VPN 
  } 
 
  ingress { 
    description     = "Tráfico de aplicación desde el frontend" 
    from_port       = 3000 # O el puerto que use tu backend (ej. 3000, 
8080, 5000) 
    to_port         = 3000 
    protocol        = "tcp" 
    security_groups = [aws_security_group.frontend_sg.id] # Solo desde 
el SG del frontend 
  } 
 
  # Regla de egreso (salida) para permitir todo el tráfico saliente 
  egress { 
    from_port   = 0 
    to_port     = 0 
    protocol    = "-1" 
    cidr_blocks = ["0.0.0.0/0"] 
  } 
 
  tags = { 
    Name = "${var.project_name}-Backend-SG" 
  } 
} 
# --- Instancia EC2 para el Frontend --- 
resource "aws_instance" "frontend_instance" { 
  ami           = var.ami_id 
  instance_type = var.instance_type_frontend 
  subnet_id     = aws_subnet.public.id 
  vpc_security_group_ids = [aws_security_group.frontend_sg.id] 
  key_name      = var.key_pair_name # Asegúrate que este Key Pair 
existe en AWS 
 
  # Opcional: Script para instalar dependencias o desplegar el 
frontend 
  user_data = <<-EOF 
              #!/bin/bash 
              sudo apt update -y 
              sudo apt install -y nginx # Ejemplo: Instalar Nginx para 
servir el frontend 
              # Aquí puedes agregar comandos para clonar tu repo de 
frontend, 
              # instalar Node.js, npm, construir la app y configurar 
Nginx. 
              # Ejemplo: 
              # git clone 
https://github.com/tu_usuario/tu_frontend.git /var/www/html/ 
              # cd /var/www/html/ 
              # npm install && npm run build 
              # sudo systemctl start nginx 
              # sudo systemctl enable nginx 
              EOF 
 
  tags = { 
    Name    = "${var.project_name}-FrontendInstance" 
    Purpose = "Frontend" 
  } 
} 
 
# --- Instancia EC2 para el Backend --- 
resource "aws_instance" "backend_instance" { 
  ami           = var.ami_id 
  instance_type = var.instance_type_backend 
  subnet_id     = aws_subnet.public.id # Si tu backend necesita ser 
accesible desde internet (ej. para APIs públicas) 
  vpc_security_group_ids = [aws_security_group.backend_sg.id] 
  key_name      = var.key_pair_name # Asegúrate que este Key Pair 
existe en AWS 
 
  # Opcional: Script para instalar dependencias o desplegar el backend 
  user_data = <<-EOF 
              #!/bin/bash 
              sudo apt update -y 
              sudo apt install -y openjdk-17-jdk # Ejemplo: Instalar 
Java para una app Spring Boot 
              # Aquí puedes agregar comandos para clonar tu repo de 
backend, 
              # instalar Docker, ejecutar contenedores, etc. 
              # Ejemplo: 
              # git clone https://github.com/tu_usuario/tu_backend.git 
/opt/backend 
              # cd /opt/backend 
              # mvn clean install 
              # java -jar target/tu-backend.jar & 
              EOF 
 
  tags = { 
    Name    = "${var.project_name}-BackendInstance" 
    Purpose = "Backend" 
  } 
}