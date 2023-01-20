# -----------------------------------------------------------------------------
# Variables: API Gateway
# -----------------------------------------------------------------------------

variable "api_throttling_rate_limit" {
  description = "API Gateway total requests across all API's within a REST endpoint"
  default     = 1000

}

variable "api_throttling_burst_limit" {
  description = "API Gateway total concurrent connections allowed for all API's within a REST endpoint"
  default     = 1000
}

variable "data_trace_enabled" {
  description = ""
  default     = true
}

variable "logging_level" {
  description = ""
  default     = "INFO"
}

variable "api_metrics_enabled" {
  description = "Enables detailed API Gateway metrics"
  type        = bool
  default     = true
}

variable "lambda_identity_timeout" {
  default = 1000
}
