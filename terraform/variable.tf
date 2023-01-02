# -----------------------------------------------------------------------------
# Variables: API Gateway
# -----------------------------------------------------------------------------

variable "api_throttling_rate_limit" {
  description = "API Gateway total requests across all API's within a REST endpoint"
  default     = 5

}

variable "api_throttling_burst_limit" {
  description = "API Gateway total concurrent connections allowed for all API's within a REST endpoint"
  default     = 5
}

variable "api_metrics_enabled" {
  description = "Enables detailed API Gateway metrics"
  type        = bool
  default     = false
}