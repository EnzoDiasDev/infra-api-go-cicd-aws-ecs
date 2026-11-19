module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "~> 6.0"

  cluster_name = var.ambiante

  # Na v6 do módulo, "fargate_capacity_providers" foi substituído por
  # "default_capacity_provider_strategy" (mesmo efeito: cluster usando FARGATE).
  default_capacity_provider_strategy = {
    FARGATE = {
      weight = 100
    }
  }
}

resource "aws_cloudwatch_log_group" "api" {
  name              = "/ecs/${var.ambiante}/Go-API"
  retention_in_days = 1 # ambiente efêmero: os logs só precisam viver o tempo do teste
}

resource "aws_ecs_task_definition" "Go-API" {
  family                   = "Go-API"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.cargo.arn
  container_definitions = jsonencode(
    [
      {
        "name"      = "homolog"
        "image"     = var.imagem
        "cpu"       = 256
        "memory"    = 512
        "essential" = true
        # Envia os logs da API para o CloudWatch (sem isto, não há onde ler os erros)
        "logConfiguration" = {
          "logDriver" = "awslogs"
          "options" = {
            "awslogs-group"         = aws_cloudwatch_log_group.api.name
            "awslogs-region"        = "us-east-1"
            "awslogs-stream-prefix" = "homolog"
          }
        }
        "portMappings" = [
          {
            "containerPort" = 8000
            "hostPort"      = 8000
          }
        ]
        "environment"= [
          {
            "name"  = "HOST"
            "value" = tostring(aws_db_instance.default.address)
          },
          {
            "name"  = "DBPORT"
            "value" = tostring(aws_db_instance.default.port)
          },
          {
            "name"  = "USER"
            "value" = tostring(aws_db_instance.default.username)
          },
          {
            "name"  = "DBNAME"
            "value" = "root"
          },
          {
            "name"  = "PORT"
            "value" = "8000"
          }
        ]
        # Valores sensíveis vêm do Secrets Manager (Segredos.tf). O ECS lê o
        # segredo ao iniciar a tarefa; o formato "<arn>:<chave-json>::" pega
        # só um campo do JSON guardado no segredo.
        "secrets" = [
          {
            "name"      = "PASSWORD"
            "valueFrom" = "${aws_secretsmanager_secret.db.arn}:password::"
          },
          {
            "name"      = "API_KEY_LEITURA"
            "valueFrom" = "${aws_secretsmanager_secret.api_keys.arn}:API_KEY_LEITURA::"
          },
          {
            "name"      = "API_KEY_ADMIN"
            "valueFrom" = "${aws_secretsmanager_secret.api_keys.arn}:API_KEY_ADMIN::"
          }
        ]
      }
    ]
  )
}


resource "aws_ecs_service" "Go-API" {
  name            = "Go-API"
  cluster         = module.ecs.cluster_id
  task_definition = aws_ecs_task_definition.Go-API.arn
  desired_count   = 1
  load_balancer {
    target_group_arn = aws_lb_target_group.alvo.arn
    container_name   = "homolog"
    container_port   = 8000
  }

  network_configuration {
      subnets = module.vpc.private_subnets
      security_groups = [aws_security_group.privado.id]
      assign_public_ip = true
  }

  capacity_provider_strategy {
      capacity_provider = "FARGATE"
      weight = 1 #100/100
  }

  # O target group só pode ser usado por um serviço depois de estar ligado
  # ao load balancer (via listener). Sem isso, o apply pode falhar com
  # "target group does not have an associated load balancer".
  # Os segredos precisam ter um valor gravado antes de a primeira tarefa subir;
  # senão o ECS não consegue ler PASSWORD e as chaves de API.
  depends_on = [
    aws_lb_listener.http,
    aws_secretsmanager_secret_version.db,
    aws_secretsmanager_secret_version.api_keys,
  ]
}
