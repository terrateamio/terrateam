# IAM Role for IoT Events
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["iotevents.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# IAM Role policy for IoT Events to publish to SNS
data "aws_iam_policy_document" "iotevents_policy" {
  statement {
    effect = "Allow"
    actions = [
      "sns:Publish"
    ]
    resources = [awscc_sns_topic.alarm_topic.topic_arn]
  }
}

# Create the IAM role for IoT Events using AWSCC
resource "awscc_iam_role" "iotevents_role" {
  role_name                   = "IoTEventsAlarmRole"
  path                        = "/"
  assume_role_policy_document = data.aws_iam_policy_document.assume_role.json

  policies = [
    {
      policy_name     = "IoTEventsPublishToSNS"
      policy_document = data.aws_iam_policy_document.iotevents_policy.json
    }
  ]

  tags = [{
    key   = "Modified By"
    value = "AWSCC"
  }]
}

# Create IoT Events Input for Temperature Sensor
resource "awscc_iotevents_input" "temp_sensor" {
  input_name        = "TemperatureSensor"
  input_description = "Input for temperature sensor readings"

  input_definition = {
    attributes = [
      {
        json_path = "temperature"
      },
      {
        json_path = "device_id"
      },
      {
        json_path = "timestamp"
      }
    ]
  }

  tags = [
    {
      key   = "Modified By"
      value = "AWSCC"
    }
  ]
}

# Create SNS topic for alarm notifications using AWSCC
resource "awscc_sns_topic" "alarm_topic" {
  topic_name = "temperature-alarm-topic"
  tags = [{
    key   = "Modified By"
    value = "AWSCC"
  }]
}

# Create the IoT Events Alarm Model
resource "awscc_iotevents_alarm_model" "temperature_alarm" {
  alarm_model_name        = "HighTemperatureAlarm"
  alarm_model_description = "Alarm for high temperature readings"
  role_arn                = awscc_iam_role.iotevents_role.arn

  alarm_rule = {
    simple_rule = {
      comparison_operator = "GREATER"
      input_property      = "$input.TemperatureSensor.temperature"
      threshold           = "30"
    }
  }

  alarm_capabilities = {
    initialization_configuration = {
      disabled_on_initialization = false
    }
    acknowledge_flow = {
      enabled = true
    }
  }

  alarm_event_actions = {
    alarm_actions = [
      {
        sns = {
          target_arn = awscc_sns_topic.alarm_topic.topic_arn
          payload = {
            content_expression = "'{ \"alarmId\": \"$${$input.TemperatureSensor.device_id}\", \"temperature\": \"$${$input.TemperatureSensor.temperature}\", \"threshold\": \"30\", \"timestamp\": \"$${$input.TemperatureSensor.timestamp}\" }'"
            type               = "JSON"
          }
        }
      }
    ]
  }

  key      = "device_id"
  severity = 3

  tags = [
    {
      key   = "Modified By"
      value = "AWSCC"
    },
    {
      key   = "Environment"
      value = "Production"
    }
  ]
}