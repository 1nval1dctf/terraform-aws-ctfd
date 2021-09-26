output "elasticache_cluster_id" {
  value       = aws_elasticache_replication_group.default.id
  description = "Id of the ElastiCache cluster"
}

output "elasticache_security_group_id" {
  value       = aws_security_group.elasticache.id
  description = "ID of security group associated with the elasticache"
}

output "elasticache_cluster_endpoint" {
  value       = aws_elasticache_replication_group.default.primary_endpoint_address
  description = "Endpoint of the ElastiCache cluster"
}

output "elasticache_cluster_port" {
  value       = var.elasticache_cluster_port
  description = "Port of the ElastiCache cluster endpoint"
}
output "cache_connection_string" {
  value       = "redis://${aws_elasticache_replication_group.default.primary_endpoint_address}:${var.elasticache_cluster_port}"
  description = "Connection string for ElastiCache"
}
