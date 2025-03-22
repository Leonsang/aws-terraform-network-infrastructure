# Módulo de Glue
module "glue" {
  source = "../../modules/glue"

  project_name     = var.project_name
  environment      = var.environment
  scripts_bucket_id = module.s3.scripts_bucket_id
  data_bucket_id   = module.s3.data_bucket_id

  glue_version       = var.glue_config.version
  glue_python_version = var.glue_config.python_version
  worker_type        = var.glue_config.worker_type
  number_of_workers  = var.glue_config.workers_count
  job_timeout        = var.glue_config.timeout_minutes

  default_arguments = {
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-metrics"                   = "true"
    "--enable-spark-ui"                 = "true"
    "--spark-event-logs-path"          = "s3://${module.s3.scripts_bucket_id}/spark-logs"
    "--enable-job-insights"            = "true"
    "--job-bookmark-option"           = "job-bookmark-enable"
    "--TempDir"                       = "s3://${module.s3.scripts_bucket_id}/temporary"
    "--extra-py-files"               = "s3://${module.s3.scripts_bucket_id}/dependencies/fraud_detection_utils.zip"
    "--environment"                  = "production"
  }

  alarm_actions = [module.sns.alert_topic_arn]
  tags         = local.tags

  depends_on = [
    module.s3,
    module.sns
  ]
} 