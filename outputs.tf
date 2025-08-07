# Outputs
output "homework_submissions_bucket_1" {
  value = aws_s3_bucket.homework_submissions_1.bucket
}

output "homework_submissions_bucket_arn_1" {
  value = aws_s3_bucket.homework_submissions_1.arn
}

output "homework_submission_topic_arn_1" {
  value = aws_sns_topic.homework_submission_topic_1.arn
}

output "homework_uploads_table_arn_1" {
  value = aws_dynamodb_table.homework_uploads_table_1.arn
}

output "feedback_table_arn_1" {
  value = aws_dynamodb_table.feedback_table_1.arn
}

output "signups_table_arn_1" {
  value = aws_dynamodb_table.signups_table_1.arn
}
