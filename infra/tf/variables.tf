variable "env" {
  description = "Ambiente di destinazione (dev, test, prod)"
  type        = string
  default     = "test"
  validation {
    condition     = contains(["dev", "test", "prod"], var.env)
    error_message = "env deve essere dev, test o prod."
  }
}

variable "owner" {
  description = "Squadra responsabile della risorsa (governance ITS)"
  type        = string
  default     = "squadra-0"
  validation {
    condition     = length(var.owner) >= 3
    error_message = "owner deve avere almeno 3 caratteri."
  }
}

variable "aws_endpoint" {
  description = "Endpoint AWS alternativo. Vuoto = AWS vero, http://127.0.0.1:5000 = moto (finto-AWS)"
  type        = string
  default     = ""
}
