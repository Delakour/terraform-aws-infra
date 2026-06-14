output "alb_arn" {
  value = aws_lb.alb.arn
}

output "alb_dns_name" {
  value = aws_lb.alb.dns_name
}

output "alb_zone_id" {
  value = aws_lb.alb.zone_id
}

output "target_group_arn" {
  value = aws_lb_target_group.app_tg.arn
}

output "onlyoffice_target_group_arn" {
  value = try(aws_lb_target_group.onlyoffice_tg[0].arn, "")
}