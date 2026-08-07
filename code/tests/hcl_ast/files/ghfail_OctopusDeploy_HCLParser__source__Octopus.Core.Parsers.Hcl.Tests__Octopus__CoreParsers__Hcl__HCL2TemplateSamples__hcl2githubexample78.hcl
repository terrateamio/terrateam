locals {
  monitor_enabled = "${var.enabled && length(var.recipients) > 0 ? 1 : 0}"
}

resource "datadog_timeboard" "sqs" {
  title       = "${var.product_domain} - ${var.queue_name} - ${var.environment} - SQS"
  description = "A generated timeboard for SQS"

  template_variable {
    default = "${var.queue_name}"
    name    = "queue_name"
    prefix  = "queuename"
  }

  template_variable {
    default = "${var.environment}"
    name    = "environment"
    prefix  = "environment"
  }

  graph {
    title     = "Sent Message Size"
    viz       = "timeseries"
    autoscale = true

    request {
      q    = "avg:aws.sqs.sent_message_size{$queue_name, $environment} by {queuename}"
      type = "line"
    }
  }

  graph {
    title     = "Approximate Age of Oldest Message"
    viz       = "timeseries"
    autoscale = true

    request {
      q    = "avg:aws.sqs.approximate_age_of_oldest_message{$queue_name, $environment} by {queuename}"
      type = "line"
    }
  }

  graph {
    title     = "Approximate Number of Messages Delayed"
    viz       = "timeseries"
    autoscale = true

    request {
      q    = "avg:aws.sqs.approximate_number_of_messages_delayed{$queue_name, $environment} by {queuename}"
      type = "line"
    }
  }

  graph {
    title     = "Approximate Number of Messages Not Visible"
    viz       = "timeseries"
    autoscale = true

    request {
      q    = "avg:aws.sqs.approximate_number_of_messages_not_visible{$queue_name, $environment} by {queuename}"
      type = "line"
    }
  }

  graph {
    title     = "Approximate Number of Messages Visible"
    viz       = "timeseries"
    autoscale = true

    request {
      q    = "avg:aws.sqs.approximate_number_of_messages_visible{$queue_name, $environment} by {queuename}"
      type = "line"
    }
  }

  graph {
    title     = "Number of Empty Receives"
    viz       = "timeseries"
    autoscale = true

    request {
      q    = "avg:aws.sqs.number_of_empty_receives{$queue_name, $environment} by {queuename}"
      type = "line"
    }
  }

  graph {
    title     = "Number of Messages Deleted"
    viz       = "timeseries"
    autoscale = true

    request {
      q    = "avg:aws.sqs.number_of_messages_deleted{$queue_name, $environment} by {queuename}"
      type = "line"
    }
  }

  graph {
    title     = "Number of Messages Received"
    viz       = "timeseries"
    autoscale = true

    request {
      q    = "avg:aws.sqs.number_of_messages_received{$queue_name, $environment} by {queuename}"
      type = "line"
    }
  }

  graph {
    title     = "Number of Messages Sent"
    viz       = "timeseries"
    autoscale = true

    request {
      q    = "avg:aws.sqs.number_of_messages_sent{$queue_name, $environment} by {queuename}"
      type = "line"
    }
  }
}