data "aws_ssm_parameter" "instance_ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}
# create an ECR 
#Terraform will communicate with AWS and create an ECR named quizapp-repo
resource "aws_ecr_repository" "quizapp-repo" {
  name = "quizapp-repo"
}

# Lets create a cluster where we will run the task
# This will instruct ECS to create a new cluster named quizapp-cluster
resource "aws_ecs_cluster" "quizapp-cluster" {
  name = "quizapp-cluster" # Name of the cluster here
}

# Write the configuration for the task requirement to spin up the Docker container. 
#Terraform will automate all this.

resource "aws_ecs_task_definition" "quizapp-task" {
  family                   = "quizapp-first-task" # Task name
  container_definitions    = <<DEFINITION
  [
    {
      "name": "quizapp-first-task",
      "image": "${aws_ecr_repository.quizapp-repo.repository_url}",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 3000,
          "hostPort": 3000
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/quiz-app",
          "awslogs-region": "eu-west-2",
          "awslogs-stream-prefix": "ecs"
        }
      },
      "memory": 512,
      "cpu": 256
    }
  ]
  DEFINITION
  requires_compatibilities = ["FARGATE"] # use Fargate as the launch type
  network_mode             = "awsvpc"    # add the AWS network mode as this is required for Fargate
  memory                   = 512         # Specifying the memory the container requires
  cpu                      = 256         # Specifying the CPU the container requires
  execution_role_arn       = "${aws_iam_role.quizapp_ecs_role.arn}"
}

# A task definition requires ecsTaskExecutionRole to be added to IAM.
# This create a resource to execute this role


 resource "aws_iam_role" "quizapp_ecs_role" {
  name               = "quizapp_ecs_role"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role_policy.json}"
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

 resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = "${aws_iam_role.quizapp_ecs_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Create a default VPC and subnets information for the AWS availability zones
# Provide a reference to your default VPC
resource "aws_default_vpc" "default_vpc" {
}

# Provide references to your default subnets
resource "aws_default_subnet" "default_subnet_a" {
  # Our own region here but reference to subnet 1a
  availability_zone = "eu-west-2a"
}

resource "aws_default_subnet" "default_subnet_b" {
  # Our own region here but reference to subnet 1b
  availability_zone = "eu-west-2b"
}

# The configuration creates a load balancer that will distribute the workloads across multiple 
# resources to ensure application’s availability, scalability, and security
# create a security group that will route the HTTP traffic using a load balancer
resource "aws_alb" "application_lb" {
  name               = "quizapp-lb" #load balancer name
  load_balancer_type = "application"
  subnets = [ # Referencing the default subnets
    "${aws_default_subnet.default_subnet_a.id}",
    "${aws_default_subnet.default_subnet_b.id}"
  ]
  # security group
  security_groups = ["${aws_security_group.load_balancer_security_group.id}"]
}

# This part of allowing HTTP traffic to access the ECS cluster to create a security group.
# Create a security group for the load balancer:
resource "aws_security_group" "load_balancer_security_group" {
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow traffic in from all sources
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # All kinds of traffic is allowed from all source
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Access the ECS service over HTTP while ensuring the VPC is more secure
# Create security groups that will only allow the traffic from the created load balancer.
resource "aws_security_group" "service_security_group" {
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    # Only allowing traffic in from the load balancer security group
    security_groups = ["${aws_security_group.load_balancer_security_group.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Configure the load balancer with the VPC networking we created
#This will distribute the balancer traffic to the available zone
resource "aws_lb_target_group" "target_group" {
  name        = "quizapp-target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = "${aws_default_vpc.default_vpc.id}" # default VPC
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = "${aws_alb.application_lb.arn}" #  load balancer
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.target_group.arn}" # target group
  }
}

# Create an ECS Service and its details to maintain task definition the Amazon ECS cluster 
# The service will run the cluster, task, and Fargate behind the created load balancer 
# to distribute traffic across the containers that are associated with the service
resource "aws_ecs_service" "app_service" {
  name            = "quizapp-first-service"     # Name the service
  cluster         = "${aws_ecs_cluster.quizapp-cluster.id}"   # Reference the created Cluster
  task_definition = "${aws_ecs_task_definition.quizapp-task.arn}" # Reference the task that the service will spin up
  launch_type     = "FARGATE"
  desired_count   = 3 # Set up the number of containers to 3

  load_balancer {
    target_group_arn = "${aws_lb_target_group.target_group.arn}" # Reference the target group
    container_name   = "${aws_ecs_task_definition.quizapp-task.family}"
    container_port   = 3000 # Specify the container port
  }

  network_configuration {
    subnets          = ["${aws_default_subnet.default_subnet_a.id}", "${aws_default_subnet.default_subnet_b.id}"]
    assign_public_ip = true     # Provide the containers with public IPs
    security_groups  = ["${aws_security_group.service_security_group.id}"] # Set up the security group
  }
}



# Using autoscaling target tracking scaling policy as it allows CloudWatch metric 
# and a target value that represents the ideal average utilization or throughput level
# for application. Auto Scaling can then scale out your group (add more instances) 
# to handle peak traffic, and scale in your group (run fewer instances) to reduce costs during 
# periods of low utilization or throughput.
resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 4
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.quizapp-cluster.name}/${aws_ecs_service.app_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}



resource "aws_appautoscaling_policy" "ecs_autoscaling_cpu" {
  name               = "ecs_autoscaling_cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value       = 75
    scale_in_cooldown  = 300
    scale_out_cooldown = 60

  }
}

# we are using CloudWatch metrics to monitor resources,applications, troubleshoot problems
#and optimize performance. Also create alarms that will notify if a metric exceeds a threshold.
resource "aws_cloudwatch_metric_alarm" "cpu_utilization_alarm" {
  alarm_name = "ecs_cpu_utilization_alarm"
  alarm_description = "Scale up ECS service if CPU utilization is too high"
  # The arithmetic operation to use when comparing the specified Statistic and Threshold. 
  #The specified Statistic value is used as the first operand.
  comparison_operator = "GreaterThanOrEqualToThreshold" 
  metric_name = "CPUUtilization"
  namespace = "AWS/ECS"
  # The dimensions for the alarm's associated metric.
  # Metrics for a dimension only reflect the resources with running tasks during a period.
  dimensions = {
    "quizapp-cluster" = "${aws_ecs_cluster.quizapp-cluster.name}"
    "app_service" = "${aws_ecs_service.app_service.name}"
    }
  
  statistic = "Average"
  # The period in seconds over which the specified statistic is applied. 
  # Valid values are 10, 30, or any multiple of 60.
  period = 60
  threshold = 80
  # The number of periods over which data is compared to the specified threshold.
  evaluation_periods = 2
  # The list of actions to execute when alarm transitions into an ALARM state from any other state. 
  # Each action is specified as an Amazon Resource Name (ARN).
  alarm_actions = ["${aws_appautoscaling_policy.ecs_autoscaling_cpu.arn}"]
}

resource "aws_cloudwatch_log_group" "quiz_app_logs"{
  name = "/ecs/quiz-app"
  retention_in_days = 14
  
} 