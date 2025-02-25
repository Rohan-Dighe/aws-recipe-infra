output "s3_recipe_bucket_name" {
  value = aws_s3_bucket.recipe_storage.bucket
}

output "s3_archive_bucket_name" {
  value = aws_s3_bucket.recipe_archives.bucket
}

output "lambda_function_name" {
  value = aws_lambda_function.zip_files.function_name
}

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.recipe_distribution.id
}
