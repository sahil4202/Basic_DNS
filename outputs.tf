output "available_images" {
  value = data.digitalocean_images.available.images[0].name
}
output "public_ip" {
  value = resource.digitalocean_droplet.web-server.ipv4_address
}
