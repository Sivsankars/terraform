resource "aws_cloudfront_origin_access_identity" "s3_identity" {
    comment = "CloudFront Origin Identity for accessing S3"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
    depends_on = [
        aws_s3_bucket.buckets,
        aws_cloudfront_origin_access_identity.s3_identity
    ]  

    origin {
        domain_name = aws_s3_bucket.buckets.bucket_regional_domain_name
        origin_id   = aws_s3_bucket.buckets.bucket_regional_domain_name
         s3_origin_config {
            origin_access_identity = aws_cloudfront_origin_access_identity.s3_identity.cloudfront_access_identity_path
        }
    }
    
    enabled             = true
    is_ipv6_enabled     = true
    comment             = "Some comment"
    default_root_object = "mypic"

    default_cache_behavior {
        allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
        cached_methods   = ["GET", "HEAD"]
        target_origin_id = aws_s3_bucket.buckets.bucket_regional_domain_name
        
        forwarded_values {
            query_string = false
            cookies {
                forward = "none"
            }
        }
        
        viewer_protocol_policy = "allow-all"
        min_ttl                = 0
        default_ttl            = 3600
        max_ttl                = 86400
    }
    
    ordered_cache_behavior {
        path_pattern     = "/content/immutable/*"
        allowed_methods  = ["GET", "HEAD", "OPTIONS"]
        cached_methods   = ["GET", "HEAD", "OPTIONS"]
        target_origin_id = aws_s3_bucket.buckets.bucket_regional_domain_name
        
        forwarded_values {
            query_string = false
            headers      = ["Origin"]
            
            cookies {
                forward = "none"
            }
        }
        
        min_ttl                = 0
        default_ttl            = 86400
        max_ttl                = 31536000
        compress               = true
        viewer_protocol_policy = "allow-all"
    }
    
    ordered_cache_behavior {
        path_pattern     = "/content/*"
        allowed_methods  = ["GET", "HEAD", "OPTIONS"]
        cached_methods   = ["GET", "HEAD"]
        target_origin_id  = aws_s3_bucket.buckets.bucket_regional_domain_name
        
        forwarded_values {
            query_string = false
            
            cookies {
                forward = "none"
            }
        }
        
        min_ttl                = 0
        default_ttl            = 3600
        max_ttl                = 86400
        compress             = true
        viewer_protocol_policy = "redirect-to-https"
    }
    
    price_class = "PriceClass_200"
    
    restrictions {
        geo_restriction {
            restriction_type = "whitelist"
            locations        = ["US", "CA", "GB", "IN"]
        }
    }
    
    viewer_certificate {
        cloudfront_default_certificate = true
    }
}
