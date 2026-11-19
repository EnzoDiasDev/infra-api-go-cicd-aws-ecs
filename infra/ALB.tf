# Exceção aceita na varredura de IaC: o load balancer é a porta de entrada
# pública da API, então precisa ser exposto à internet.
#trivy:ignore:AWS-0053
resource "aws_lb" "alb" {
  name               = "ECS-Go"
  security_groups    = [aws_security_group.alb.id]
  subnets            = module.vpc.public_subnets
  # Descarta cabeçalhos HTTP malformados antes de chegarem à API.
  drop_invalid_header_fields = true
}

# Exceção aceita na varredura de IaC: ainda sem HTTPS (precisa de domínio e
# certificado no ACM). Pendência registrada no SSDLC, fase 2 (tráfego sem TLS).
#trivy:ignore:AWS-0054
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alvo.arn
  }
}

resource "aws_lb_target_group" "alvo" {
  name        = "ECS-Go"
  port        = 8000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = module.vpc.vpc_id
  health_check {
    path = "/leo"
  }
}

output "IP" {
  value = aws_lb.alb.dns_name
}
