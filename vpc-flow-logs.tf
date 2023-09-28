
resource "aws_iam_role" "vpc_flow_logs_log_group_role" {
  name = "vpc-flow-logs-log-group"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",        
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      }
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "vpcflowlogsn_role_loggroup_role_policy_attach" {
  role       = aws_iam_role.vpc_flow_logs_log_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_cloudwatch_log_group" "vpc_flow_logs_log_group" {
  name              = "vpc-flow-logs-log-group"
  retention_in_days = 5
}

resource "aws_flow_log" "vpc_flow_log" {
  iam_role_arn    = aws_iam_role.vpc_flow_logs_log_group_role.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs_log_group.arn
  traffic_type    = "ALL"
  eni_id          = aws_instance.db_server.primary_network_interface_id
}

