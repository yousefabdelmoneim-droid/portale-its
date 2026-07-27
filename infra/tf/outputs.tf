output "bucket_sito" {
  description = "Bucket che ospita il portale"
  value       = aws_s3_bucket.sito.id
}

output "bucket_log" {
  description = "Bucket dei log di accesso"
  value       = aws_s3_bucket.log.id
}

output "tabella_iscrizioni" {
  description = "Tabella delle iscrizioni"
  value       = aws_dynamodb_table.iscrizioni.name
}
