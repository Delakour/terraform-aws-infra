resource "aws_ssm_parameter" "parameter" {
  for_each = var.parameters

  name        = "/parpar/${var.env}/${each.key}"
  description = each.value.description
  type        = each.value.type
  value = coalesce(
    try(each.value.placeholder, null),
    "__UNSET__"
  )

  overwrite = false

  lifecycle {
    ignore_changes = [value]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-ssm-${each.key}"
  })
}
