resource "aws_s3_bucket" "buckets" {
    bucket = var.bucketname
    acl = "private"

    server_side_encryption_configuration {
        rule {
            apply_server_side_encryption_by_default {
                sse_algorithm = "AES256"
            }
        }
    }

    versioning {
        enabled = false
    }

    logging {
        target_bucket = "" // Specify your logging bucket
        target_prefix = "" // Specify the prefix for log files
    }

    acceleration_status   = "Suspended"
    object_lock_enabled  = false
    website {
        index_document = "index.html"
        error_document = "error.html"
    }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
    bucket = aws_s3_bucket.buckets.id

    policy = jsonencode({
        Version = "2012-10-17",
        Id      = "PolicyForCloudFrontPrivateContent",
        Statement = [
            {
                Sid       = "1",
                Effect    = "Allow",
                Principal = {
                    AWS = "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity ${aws_cloudfront_origin_access_identity.s3_identity.iam_arn}"
                },
                Action    = "s3:GetObject",
                Resource  = "${aws_s3_bucket.buckets.arn}/*"
            },
            {
                Sid       = "AllowCloudFrontServicePrincipal",
                Effect    = "Allow",
                Principal = {
                    Service = "cloudfront.amazonaws.com"
                },
                Action    = "s3:GetObject",
                Resource  = "${aws_s3_bucket.buckets.arn}/*",
                Condition = {
                    StringEquals = {
                        "AWS:SourceArn" = aws_cloudfront_distribution.s3_distribution.arn
                    }
                }
            }
        ]
    })
}
