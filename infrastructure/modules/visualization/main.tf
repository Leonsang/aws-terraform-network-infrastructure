locals {
  analysis_name = "${var.project_name}-fraud-analysis-${var.environment}"
  dataset_name  = "${var.project_name}-fraud-dataset-${var.environment}"
}

# Rol IAM para QuickSight
resource "aws_iam_role" "quicksight_role" {
  name = "${var.project_name}-quicksight-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "quicksight.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Política para acceso a Athena y S3
resource "aws_iam_role_policy" "quicksight_policy" {
  name = "${var.project_name}-quicksight-policy-${var.environment}"
  role = aws_iam_role.quicksight_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "athena:StartQueryExecution",
          "athena:GetQueryExecution",
          "athena:GetQueryResults",
          "athena:StopQueryExecution",
          "athena:ListQueryExecutions"
        ]
        Resource = [
          "arn:aws:athena:${var.aws_region}:${var.account_id}:workgroup/primary"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = [
          "${var.processed_data_bucket_arn}/*",
          "${var.processed_data_bucket_arn}",
          "${var.athena_output_bucket_arn}/*",
          "${var.athena_output_bucket_arn}"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "glue:GetTable",
          "glue:GetTables",
          "glue:GetDatabase",
          "glue:GetDatabases"
        ]
        Resource = [
          "arn:aws:glue:${var.aws_region}:${var.account_id}:catalog",
          "arn:aws:glue:${var.aws_region}:${var.account_id}:database/${var.glue_database_name}",
          "arn:aws:glue:${var.aws_region}:${var.account_id}:table/${var.glue_database_name}/*"
        ]
      }
    ]
  })
}

# Dataset de QuickSight
resource "aws_quicksight_data_set" "fraud_dataset" {
  aws_account_id = var.account_id
  data_set_id    = local.dataset_name
  name           = local.dataset_name
  physical_table_id = "fraud_transactions"
  import_mode    = "DIRECT_QUERY"

  permissions {
    principal  = var.quicksight_principal_arn
    actions    = ["quicksight:DescribeDataSet", "quicksight:DescribeDataSetPermissions", "quicksight:PassDataSet", "quicksight:UpdateDataSet", "quicksight:DeleteDataSet"]
  }

  physical_table_definition {
    custom_sql {
      data_source_arn = var.athena_data_source_arn
      name            = "fraud_transactions"
      sql_query       = <<EOF
        SELECT 
          transaction_id,
          customer_id,
          timestamp,
          amount,
          merchant_category,
          is_fraud,
          risk_score,
          CAST(DATE_TRUNC('hour', timestamp) AS timestamp) as hour,
          CAST(DATE_TRUNC('day', timestamp) AS timestamp) as day,
          CAST(DATE_TRUNC('month', timestamp) AS timestamp) as month
        FROM ${var.glue_database_name}.transactions
      EOF
    }
  }

  logical_table_map {
    logical_table_map_id = "fraud_transactions"
    alias               = "Fraud Transactions"
    source {
      physical_table_id = "fraud_transactions"
    }
  }

  tags = var.tags
}

# Dashboard de QuickSight
resource "aws_quicksight_dashboard" "fraud_dashboard" {
  aws_account_id = var.account_id
  dashboard_id   = "${var.project_name}-fraud-dashboard-${var.environment}"
  name           = "Fraud Detection Dashboard"
  version_description = "Initial version"

  source_entity {
    source_template {
      data_set_references {
        data_set_arn = aws_quicksight_data_set.fraud_dataset.arn
        data_set_placeholder = "fraud_transactions"
      }
    }
  }

  permissions {
    principal  = var.quicksight_principal_arn
    actions    = ["quicksight:DescribeDashboard", "quicksight:ListDashboardVersions", "quicksight:UpdateDashboardPermissions", "quicksight:QueryDashboard", "quicksight:UpdateDashboard", "quicksight:DeleteDashboard", "quicksight:DescribeDashboardPermissions", "quicksight:UpdateDashboardPublishedVersion"]
  }

  dashboard_publish_options {
    ad_hoc_filtering_option {
      availability_status = "ENABLED"
    }
    export_to_csv_option {
      availability_status = "ENABLED"
    }
    sheet_controls_option {
      visibility_state = "EXPANDED"
    }
  }

  tags = var.tags
}

# Análisis de QuickSight
resource "aws_quicksight_analysis" "fraud_analysis" {
  aws_account_id = var.account_id
  analysis_id    = local.analysis_name
  name           = "Fraud Detection Analysis"

  source_entity {
    source_template {
      data_set_references {
        data_set_arn = aws_quicksight_data_set.fraud_dataset.arn
        data_set_placeholder = "fraud_transactions"
      }
    }
  }

  permissions {
    principal  = var.quicksight_principal_arn
    actions    = ["quicksight:DescribeAnalysis", "quicksight:UpdateAnalysis", "quicksight:DeleteAnalysis", "quicksight:DescribeAnalysisPermissions", "quicksight:QueryAnalysis", "quicksight:UpdateAnalysisPermissions"]
  }

  tags = var.tags
}

# Tema personalizado de QuickSight
resource "aws_quicksight_theme" "fraud_theme" {
  aws_account_id = var.account_id
  theme_id       = "${var.project_name}-theme-${var.environment}"
  name           = "Fraud Detection Theme"
  base_theme_id  = "MIDNIGHT"

  configuration {
    data_color_palette {
      colors = ["#FF4B4B", "#2ECC71", "#3498DB", "#F1C40F", "#9B59B6"]
      min_max_gradient = ["#FF4B4B", "#2ECC71"]
    }

    ui_color_palette {
      primary_foreground   = "#FFFFFF"
      primary_background   = "#2C3E50"
      secondary_background = "#34495E"
      accent              = "#3498DB"
      accent_foreground   = "#FFFFFF"
    }
  }

  permissions {
    principal  = var.quicksight_principal_arn
    actions    = ["quicksight:DescribeTheme", "quicksight:UpdateTheme", "quicksight:DeleteTheme"]
  }

  tags = var.tags
} 