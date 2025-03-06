# S3 Bucket for recipe storage
resource "aws_s3_bucket" "recipe_storage" {
  bucket = var.s3_recipe_bucket
}

# Enable versioning on the bucket
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.recipe_storage.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket for archives
resource "aws_s3_bucket" "recipe_archives" {
  bucket = var.s3_archive_bucket
}

#  Enable versioning for the archive bucket
resource "aws_s3_bucket_versioning" "archives_versioning" {
  bucket = aws_s3_bucket.recipe_archives.id
  versioning_configuration {
    status = "Enabled"
  }
}

#  S3 Bucket Policy for CloudFront Access
resource "aws_s3_bucket_policy" "recipe_archives_policy" {
  bucket = aws_s3_bucket.recipe_archives.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.oai.iam_arn
        },
        Action = "s3:GetObject",
        Resource = "arn:aws:s3:::${aws_s3_bucket.recipe_archives.bucket}/*"
      }
    ]
  })
}

# Server-side encryption for S3
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.recipe_storage.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# IAM Role for Lambda Execution
resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Lambda Function creates an AWS Lambda function named zip_receipe.
resource "aws_lambda_function" "zip_files" {
  function_name = "zip_recipes"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.8"
  timeout       = 60

  filename         = "lambda_function.zip"
  source_code_hash = filebase64sha256("lambda_function.zip")

  environment {
    variables = {
      OUTPUT_BUCKET = aws_s3_bucket.recipe_archives.bucket
    }
  }
}

#  Add permission for S3 to invoke Lambda
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.zip_files.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.recipe_storage.arn
}

# S3 Bucket Notification for Lambda Trigger
resource "aws_s3_bucket_notification" "bucket_notifications" {
  bucket = aws_s3_bucket.recipe_storage.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.zip_files.arn
    events             = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3]  #  Ensure permission is created first
}

#  CloudFront Origin Access Identity (OAI)
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for Recipe Distribution CloudFront"
}

#  CloudFront Distribution for Secure Global Access
resource "aws_cloudfront_distribution" "recipe_distribution" {
  origin {
    domain_name = aws_s3_bucket.recipe_archives.bucket_regional_domain_name
    origin_id   = "S3-RecipeArchives"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  enabled = true
  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-RecipeArchives"

    #  FIX: Added ForwardedValues block
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

#  IAM Policy for Lambda to Access S3 Buckets
resource "aws_iam_policy" "lambda_s3_access" {
  name        = "lambda_s3_access_policy"
  description = "Policy to allow Lambda to access S3 buckets"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.recipe_storage.bucket}",        #  Allow listing objects
          "arn:aws:s3:::${aws_s3_bucket.recipe_storage.bucket}/*",      #  Allow reading objects
          "arn:aws:s3:::${aws_s3_bucket.recipe_archives.bucket}",       #  Allow listing objects
          "arn:aws:s3:::${aws_s3_bucket.recipe_archives.bucket}/*"      #  Allow writing objects
        ]
      }
    ]
  })
}

# Attach the Lambda S3 access policy to Lambda Execution Role
resource "aws_iam_role_policy_attachment" "lambda_s3_attachment" {
  policy_arn = aws_iam_policy.lambda_s3_access.arn
  role       = aws_iam_role.lambda_exec.name
}

#  IAM Policy for Lambda to Write Logs to CloudWatch
resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging_policy"
  description = "Allow Lambda to write logs to CloudWatch"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

#  Attach Logging Policy to Lambda Execution Role
resource "aws_iam_role_policy_attachment" "lambda_logging_attachment" {
  policy_arn = aws_iam_policy.lambda_logging.arn
  role       = aws_iam_role.lambda_exec.name
}

# Enabled S3 Lifecycle Rules for both S3 buckets
resource "aws_s3_bucket_lifecycle_configuration" "recipe_storage_lifecycle" {
  bucket = aws_s3_bucket.recipe_storage.id

  rule {
    id     = "MoveToGlacier"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "GLACIER"
    }
  }

  rule {
    id     = "ExpireOldFiles"
    status = "Enabled"

    expiration {
      days = 180
    }
  }

  rule {
    id     = "AbortIncompleteUploads"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "recipe_archives_lifecycle" {
  bucket = aws_s3_bucket.recipe_archives.id

  rule {
    id     = "ExpireArchivedFiles"
    status = "Enabled"

    expiration {
      days = 365  # Delete files older than 1 year
    }
  }

  rule {
    id     = "AbortIncompleteUploadsArchives"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

