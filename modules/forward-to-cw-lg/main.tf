
# forwarding all events
resource "aws_cloudwatch_event_bus_policy" "central_bus_policy_attach" {
  policy         = data.aws_iam_policy_document.central_bus_policy.json
  event_bus_name = var.settings.eventbus_name
}


resource "aws_cloudwatch_event_rule" "forward_to_cw_lg" {
  name           = "forward_to_cw_lg_${var.settings.cw_lg.lg_name}"
  event_bus_name = var.settings.eventbus_name
  event_pattern  = var.settings.cw_lg.event_pattern
}

resource "aws_cloudwatch_event_target" "forward_to_cw_lg" {
  rule           = aws_cloudwatch_event_rule.eventsrule_cw_lg.name
  event_bus_name = var.settings.eventbus_name
  target_id      = "SendtoCwLg"
  arn            = aws_cloudwatch_log_group.backup_alerts.arn
}

resource "aws_cloudwatch_log_group" "events_dump" {
  name              = var.settings.cw_lg.lg_name
  skip_destroy      = var.settings.cw_lg.lg_skip_destroy
  retention_in_days = var.settings.cw_lg.lg_retention_in_days
  kms_key_id        = aws_kms_key.cloudwatch_logs.arn
}

data "aws_iam_policy_document" "events_dump_policy" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
        aws_cloudwatch_log_group.events_dump.arn
    ]

    principals {
      type = "Service"
      identifiers = [
        "events.amazonaws.com",
        "delivery.logs.amazonaws.com"
      ]
    }
  }
}

resource "aws_cloudwatch_log_resource_policy" "events_dump_policy" {
  policy_document = data.aws_iam_policy_document.events_dump_policy.json
  policy_name     = "${aws_cloudwatch_log_group.events_dump.name}-policy"
}
