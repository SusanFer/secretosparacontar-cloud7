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
  map_public_ip_on_launch = true # Para que las instancias obtengan una IP pública 
  availability_zone       = "${var.aws_region}a" # Puedes usar una zona de disponibilidad específica 
 
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
 
# --- Instancia EC2 para el Frontend --- 
resource "aws_instance" "frontend_instance" { 
  ami           = var.ami_id 
  instance_type = var.instance_type_frontend 
  subnet_id     = aws_subnet.public.id 
  vpc_security_group_ids = [aws_security_group.frontend_sg.id] 
  key_name      = var.key_pair_name # Asegúrate que este Key Pair existe en AWS 
 
  # Opcional: Script para instalar dependencias o desplegar el frontend 
  user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo yum install -y git # Nginx y Node/NPM se instalarán después

    # Instalar NVM (Node Version Manager) y Node.js/npm
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    . ~/.nvm/nvm.sh
    nvm install --lts # Instala la última versión LTS de Node.js
    nvm use --lts

    # Clonar el repositorio del frontend
    git clone https://github.com/SusanFer/Secretos-para-contar-frontend.git /home/ec2-user/Secretos-para-contar-frontend

    # Navegar al directorio y construir la aplicación React
    cd /home/ec2-user/Secretos-para-contar-frontend
    npm install
    npm run build # ¡IMPORTANTE! Compilar para producción

    # Instalar y configurar Nginx
    sudo yum install -y nginx
    sudo systemctl start nginx
    sudo systemctl enable nginx

    # Limpiar el directorio HTML predeterminado de Nginx
    sudo rm -rf /usr/share/nginx/html/*
    # Copiar los archivos de la build de React al directorio de Nginx
    sudo cp -r /home/ec2-user/Secretos-para-contar-frontend/build/* /usr/share/nginx/html/

    # Configurar Nginx para servir la aplicación React (manejo de SPA routing)
    sudo bash -c 'cat << EOT > /etc/nginx/nginx.conf
    user nginx;
    worker_processes auto;
    error_log /var/log/nginx/error.log;
    pid /run/nginx.pid;

    include /usr/share/nginx/modules/*.conf;

    events {
        worker_connections 1024;
    }

    http {
        log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                          '$status $body_bytes_sent "$http_referer" '
                          '"$http_user_agent" "$http_x_forwarded_for"';

        access_log  /var/log/nginx/access.log  main;

        sendfile            on;
        tcp_nopush          on;
        tcp_nodelay         on;
        keepalive_timeout   65;
        types_hash_max_size 2048;

        include             /etc/nginx/mime.types;
        default_type        application/octet-stream;

        # Load modular configuration files from the default.d directory.
        # include /etc/nginx/default.d/*.conf; # Removido para evitar conflictos

        server {
            listen       80 default_server;
            listen       [::]:80 default_server;
            server_name  _;
            root         /usr/share/nginx/html;

            location / {
                try_files $uri $uri/ /index.html; # Esto es CRUCIAL para aplicaciones SPA (React Router)
            }

            error_page 404 /404.html;
                location = /40x.html {
            }

            error_page 500 502 503 504 /50x.html;
                location = /50x.html {
            }
        }
    }
    EOT'

    sudo systemctl restart nginx
    EOF
 
  tags = { 
    Name    = "${var.project_name}-FrontendInstance" 
    Purpose = "Frontend" 
  } 
} 
 