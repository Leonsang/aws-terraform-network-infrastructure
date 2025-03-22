module "glue" {
  source = "../../modules/glue"

  project_name     = var.project_name
  environment      = var.environment
  scripts_bucket_id = module.s3.scripts_bucket_id
  data_bucket_id   = module.s3.data_bucket_id

  glue_version       = "3.0"
  glue_python_version = "3"
  worker_type        = "G.1X"
  number_of_workers  = 5
  job_timeout        = 120

  default_arguments = {
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-metrics"                   = "true"
    "--enable-spark-ui"                 = "true"
    "--spark-event-logs-path"          = "s3://${module.s3.scripts_bucket_id}/spark-logs"
    "--enable-job-insights"            = "true"
    "--job-bookmark-option"           = "job-bookmark-enable"
  }

  alarm_actions = [module.sns.alert_topic_arn]

  tags = local.tags
} 