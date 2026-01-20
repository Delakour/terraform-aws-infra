output "domain_name" {
  value = aws_cloudfront_distribution.cloudfront.domain_name
}

output "hosted_zone_id" {
  value = aws_cloudfront_distribution.cloudfront.hosted_zone_id
}

output "distribution_arn" {
  description = "CloudFront distribution ARN"
  value       = aws_cloudfront_distribution.cloudfront.arn
}
