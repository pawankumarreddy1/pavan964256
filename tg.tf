
resource "aws_lb_target_group" "my-target-group1" {
   health_check {
    interval            = 10
    path                = "/"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }
  name     = "target-group1"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.stag-vpc.id
}
resource "aws_lb" "loadbalencer1" {
  name               = "test-lb-tf1"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.loadbalancer-sg.id]
  subnets            = ["${aws_subnet.stag-public1[0].id}", "${aws_subnet.stag-public1[1].id}"]

  enable_deletion_protection = true

  

  tags = {
    Environment = "production"
  }
}

resource "aws_lb_target_group_attachment" "application1" {
  # target_group_arn = "aws:elasticloadbalancing:ap-south-1:340567388318:targetgroup/my-test-tg/a02c39f384960b79"
  target_group_arn = aws_lb_target_group.my-target-group1.arn
  target_id        = aws_instance.application1.id
  port             = 80

}
 



