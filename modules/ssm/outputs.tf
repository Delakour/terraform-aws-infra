output "parameter_name" {
  value = [
    for p in aws_ssm_parameter.parameter : p.name
  ]
}
 output "parameter_arn" {
  value = [
    for p in aws_ssm_parameter.parameter : p.arn
  ]
 }