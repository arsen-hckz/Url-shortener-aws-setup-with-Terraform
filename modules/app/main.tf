resource "aws_security_group" "app" {
    name = "${var.environment}-app-sg"
    vpc_id = var.vpc_id


    ingress {
        description = "http from the internet"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_iam_role" "app" {
    name = "${var.environment}-app-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Effect = "Allow"
            Principal = { Service = "ec2.amazonaws.com"}
            Action = "sts:AssumeRole"
        }]
    })
}

resource "aws_iam_role_policy_attachment" "ssm" {
    role = aws_iam_role.app.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"  
}

resource "aws_iam_role_policy" "read_db_secret" {
    name = "read-db-secret"
    role = aws_iam_role.app.name
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Effect = "Allow"
            Action = "secretsmanager:GetSecretValue"
            Resource = var.db_secret_arn
            }]
    })
}

resource "aws_iam_instance_profile" "app" {
    name = "${var.environment}-app-profile"
    role = aws_iam_role.app.name
}

    data "aws_ami" "al2023" {
        most_recent = true
        owners = ["amazon"]
        
        filter {
          name = "name"
          values = ["al2023-ami-2023.*-x86_64"]
        }
    }

    resource "aws_instance" "app"{
        ami = data.aws_ami.al2023.id
        instance_type = var.instance_type
        subnet_id = var.subnet_id
        vpc_security_group_ids = [aws_security_group.app.id]
        iam_instance_profile = aws_iam_instance_profile.app.name
        user_data_replace_on_change = true
        depends_on = [ 
            aws_iam_role_policy.read_db_secret,
            aws_iam_role_policy_attachment.ssm
         ]
        

        user_data = <<-EOF
    #!/bin/bash
    set -euo pipefail

    dnf install -y docker jq
    systemctl enable --now docker

    TOKEN=$(curl -sX PUT http://169.254.169.254/latest/api/token -H "X-aws-ec2-metadata-token-ttl-seconds: 300")
    PUBLIC_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4)
    REGION=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/region)

    SECRET=$(aws secretsmanager get-secret-value --region "$REGION" --secret-id "${var.db_secret_arn}" --query SecretString --output text)
    DB_USER=$(echo "$SECRET" | jq -r .username)
    DB_PASS=$(echo "$SECRET" | jq -r .password)

    docker run -d --name shortener --restart unless-stopped -p 80:8000 \
      -e MYSQL_HOST="${var.db_host}" \
      -e MYSQL_PORT=3306 \
      -e MYSQL_DB="${var.db_name}" \
      -e MYSQL_USER="$DB_USER" \
      -e MYSQL_PASSWORD="$DB_PASS" \
      -e DJANGO_SECRET_KEY="$(openssl rand -hex 32)" \
      -e DJANGO_DEBUG=False \
      -e DJANGO_ALLOWED_HOSTS="$PUBLIC_IP" \
      -e BASE_URL="http://$PUBLIC_IP" \
      ${var.image} \
      sh -c "python manage.py migrate --noinput && gunicorn UrlShortener.wsgi:application --bind 0.0.0.0:8000"
  EOF

  tags = { Name = "${var.environment}-app" }

      
    }