# Portale corsi ITS ICT Piemonte - infrastruttura di pubblicazione (binario B - Terraform)

locals {
  suffisso = "${var.env}-${var.owner}"

  # Tag obbligatori da capitolato: il gate della pipeline verifica che Owner ci sia.
  tag_comuni = {
    Owner    = var.owner
    Env      = var.env
    Progetto = "portale-its"
  }
}

data "aws_caller_identity" "attuale" {}

# ---------- bucket dei log di accesso ----------
resource "aws_s3_bucket" "log" {
  bucket = "portale-its-log-${local.suffisso}"
  tags   = local.tag_comuni
}

resource "aws_s3_bucket_ownership_controls" "log" {
  bucket = aws_s3_bucket.log.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "log" {
  bucket = aws_s3_bucket.log.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "log" {
  bucket = aws_s3_bucket.log.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "log" {
  bucket                  = aws_s3_bucket.log.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Policy che consente a S3 di scrivere i log nel bucket dei log
resource "aws_s3_bucket_policy" "log" {
  bucket = aws_s3_bucket.log.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "ConsentiScritturaLogS3"
      Effect    = "Allow"
      Principal = { Service = "logging.s3.amazonaws.com" }
      Action    = "s3:PutObject"
      Resource  = "${aws_s3_bucket.log.arn}/*"
      Condition = {
        StringEquals = {
          "aws:SourceAccount" = data.aws_caller_identity.attuale.account_id
        }
      }
    }]
  })
}

# ---------- bucket del sito ----------
resource "aws_s3_bucket" "sito" {
  bucket = "portale-its-sito-${local.suffisso}"
  tags   = local.tag_comuni
}

resource "aws_s3_bucket_versioning" "sito" {
  bucket = aws_s3_bucket.sito.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sito" {
  bucket = aws_s3_bucket.sito.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "sito" {
  bucket                  = aws_s3_bucket.sito.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "sito" {
  bucket        = aws_s3_bucket.sito.id
  target_bucket = aws_s3_bucket.log.id
  target_prefix = "sito/${var.env}/"

  depends_on = [aws_s3_bucket_policy.log]
}

# ---------- tabella iscrizioni ----------
resource "aws_kms_key" "iscrizioni" {
  description         = "Chiave di cifratura della tabella iscrizioni del portale ITS"
  enable_key_rotation = true
  tags                = local.tag_comuni
}

resource "aws_dynamodb_table" "iscrizioni" {
  name         = "portale-its-iscrizioni-${local.suffisso}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "iscrizioneId"

  attribute {
    name = "iscrizioneId"
    type = "S"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.iscrizioni.arn
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = local.tag_comuni
}
