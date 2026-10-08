output "bucket_name" {
  description = "Bucket holding the hello-world file."
  value       = aws_s3_bucket.hello.bucket
}

output "hello_world_s3_uri" {
  description = "S3 URI of the hello-world text file."
  value       = "s3://${aws_s3_bucket.hello.bucket}/${aws_s3_object.hello.key}"
}
