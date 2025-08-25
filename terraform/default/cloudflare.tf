resource "cloudflare_dns_record" "dns_records" {
  for_each = {
    for pair in flatten([
      for domain_name, domain_config in var.cloudflare.domains : [
        for record in domain_config.records : {
          key = "${domain_name}-${record.name}"
          zone_id = domain_config.zone_id
          name = record.name
          type = record.type
          proxied = try(record.proxied, false)
          content = record.content
        }
      ]
    ]) : pair.key => pair
  }
  
  zone_id = each.value.zone_id
  name = each.value.name
  content = each.value.content
  type = each.value.type
  proxied = each.value.proxied
  ttl = 1
}
