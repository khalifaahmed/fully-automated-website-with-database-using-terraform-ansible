
resource "aws_iam_role" "es2_s3_role" {
  name = "ec2-s3-role"

  # there must not be indentation in the json policy man
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",        
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      }
    }
  ]
}
POLICY
}


resource "aws_iam_policy" "es2_s3_policy" {
  name = "es2-s3-policy"
  path = "/"

  # there must not be indentation in the json policy man
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "s3:*",        
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
POLICY
}


resource "aws_iam_role_policy_attachment" "es2_s3_role_policy_attach" {
  role       = aws_iam_role.es2_s3_role.name
  policy_arn = aws_iam_policy.es2_s3_policy.arn
}


resource "aws_iam_instance_profile" "ec2_s3_profile" {
  name = "ec2-s3-profile"
  role = aws_iam_role.es2_s3_role.name
}
