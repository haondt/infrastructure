variable "cloudflare" {
    description = "Cloudflare Configuration"
    type = object({
        api_token = string
        domains = map(object({
            zone_id = string
            records = optional(list(object({
                name = string
                type = string
                content = string
                proxied = optional(bool)
            })))
        }))
    })
}


