# Tuneable Variables

# Empty Project Message
variable "project" {
    description = "Project prefix used in names and tags"
    type = string
    default = "mt-vpc"
    validation {
        condition = length(var.project) > 0
        error_message = "Cannot have empty project"
    }
}

