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
  vpc_id                = aws_vpc.main.id 
  cidr_block            = var.public_subnet_cidr_block 
  map_public_ip_on_launch = true # Para que las instancias obtengan una IP pública 
  availability_zone     = "${var.aws_region}a" # Puedes usar una zona de disponibilidad específica 
 
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
  name          = "${var.project_name}-Frontend-SG" 
  description   = "Permitir trafico HTTP HTTPS y SSH al frontend" 
  vpc_id        = aws_vpc.main.id 
 
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
 
# --- CloudWatch Log Group ---
resource "aws_cloudwatch_log_group" "user_data_log_group" {
  name              = "${var.project_name}-user-data"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-UserDataLogGroup"
  }
}

# --- IAM Role for CloudWatch Agent ---
resource "aws_iam_role" "ec2_cloudwatch_role" {
  name = "${var.project_name}-EC2-CloudWatch-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name = "${var.project_name}-EC2-CloudWatch-Role"
  }
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent_policy" {
  role       = aws_iam_role.ec2_cloudwatch_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "ec2_cloudwatch_instance_profile" {
  name = "${var.project_name}-EC2-CloudWatch-Profile"
  role = aws_iam_role.ec2_cloudwatch_role.name
}

# --- Instancia EC2 para el Frontend ---
resource "aws_instance" "frontend_instance" {
  ami                    = var.ami_id
  instance_type          = var.instance_type_frontend
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.frontend_sg.id]
  key_name               = var.key_pair_name # Asegúrate que este Key Pair existe en AWS
  iam_instance_profile   = aws_iam_instance_profile.ec2_cloudwatch_instance_profile.name

  # user_data FINAL: Despliegue de Node.js con PM2 y Nginx como Proxy Inverso
  user_data = <<-EOF
#!/bin/bash
set -ex

# --- Variables ---
APP_DIR="/opt/app"
LOG_FILE="/var/log/user-data-final.log"

# --- Logging ---
exec > "$LOG_FILE" 2>&1

echo "--- Iniciando script user_data (v6 - Proxy Inverso) ---"

# --- Instalación de Paquetes ---
yum update -y
yum install -y git nginx

# --- Instalación de Node.js ---
curl -fsSL https://rpm.nodesource.com/setup_20.x | bash -
yum install -y nodejs

# --- Instalación de PM2 (Process Manager) ---
npm install pm2 -g

# --- Clonación y Compilación de la Aplicación ---
git clone https://github.com/SusanFer/Secretos-para-contar-frontend.git "$APP_DIR"
cd "$APP_DIR"
npm install
npm run build

# --- Iniciar la Aplicación con PM2 ---
# El comando "npm start" ejecuta el servidor de producción de Remix
pm2 start npm --name "remix-app" -- start

# --- Configurar PM2 para que se inicie con el sistema ---
# Esto genera un script de inicio y lo configura como un servicio
# El usuario 'ec2-user' es el estándar en Amazon Linux
pm2 startup systemd -u ec2-user --hp /home/ec2-user
pm2 save

# --- Configurar Nginx como Proxy Inverso ---
# Esto redirige el tráfico del puerto 80 al puerto 3000 donde corre la app
cat > /etc/nginx/conf.d/default.conf <<'EOT'
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOT

# --- Reinicio de Nginx ---
nginx -t
systemctl enable nginx
systemctl restart nginx

echo "--- Script user_data finalizado con éxito: Aplicación corriendo con PM2 y Nginx --- "
EOF

  tags = {
    Name    = "${var.project_name}-FrontendInstance"
    Purpose = "Frontend"
  }
}
