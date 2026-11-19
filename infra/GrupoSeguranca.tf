resource "aws_security_group" "alb" {
  name        = "alb_ECS"
  vpc_id      = module.vpc.vpc_id
}

resource "aws_security_group_rule" "tcp_alb" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"] #0.0.0.0 - 255.255.255.255
  security_group_id = aws_security_group.alb.id
}

# Exceção aceita na varredura de IaC: o load balancer precisa encaminhar para
# as tarefas. Restringir a saída ao security group "privado" é melhoria futura.
#trivy:ignore:AWS-0104
resource "aws_security_group_rule" "saida_alb" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"] #0.0.0.0 - 255.255.255.255
  security_group_id = aws_security_group.alb.id
}

# O banco não tem regra de saída: o security group é stateful, então as
# respostas às conexões recebidas saem sem precisar de regra de egress.
resource "aws_security_group" "db" {
  name        = "db_ECS"
  vpc_id      = module.vpc.vpc_id
}

# A porta do banco só aceita conexões vindas das tarefas do ECS (security group
# "privado"). Antes estava aberta para a internet inteira (0.0.0.0/0).
resource "aws_security_group_rule" "tcp_db" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.privado.id
  security_group_id        = aws_security_group.db.id
}

resource "aws_security_group" "privado" {
  name        = "privado_ECS"
  vpc_id      = module.vpc.vpc_id
}

resource "aws_security_group_rule" "entrada_ECS" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  source_security_group_id = aws_security_group.alb.id
  security_group_id = aws_security_group.privado.id
}

# Exceção aceita na varredura de IaC: as tarefas precisam sair para a internet
# para baixar a imagem do Docker Hub e falar com o Secrets Manager e o
# CloudWatch.
#trivy:ignore:AWS-0104
resource "aws_security_group_rule" "saida_ECS" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"] #0.0.0.0 - 255.255.255.255
  security_group_id = aws_security_group.privado.id
}
