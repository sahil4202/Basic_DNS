resource "digitalocean_droplet" "web-server" {
  image  = data.digitalocean_images.available.images[0].slug
  name   = "web-1"
  region = "fra1"
  size   = "s-1vcpu-1gb"
  ssh_keys = [
    data.digitalocean_ssh_key.terraform.id
  ]

  connection {
    host        = self.ipv4_address
    user        = "root"
    type        = "ssh"
    private_key = file(var.pvt_key)
    timeout     = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "export PATH=$PATH:/usr/bin",
      # configure non root user
      "useradd -m -s /bin/bash ubuntu",
      "usermod -aG sudo ubuntu",
      "rsync --archive --chown=ubuntu:ubuntu ~/.ssh /home/ubuntu",
      # install nginx
      "sudo apt update",
      "sudo apt install -y nginx",
      # allow ubuntu user to access nging files default path
      "chown -R ubuntu:ubuntu /var/www/html"
    ]
  }
  provisioner "local-exec" {
    command = "./deploy.sh ${self.ipv4_address}"
  }
}

data "digitalocean_images" "available" {
  filter {
    key    = "distribution"
    values = ["Ubuntu"]
  }
  filter {
    key    = "regions"
    values = ["fra1"]
  }
  filter {
    key      = "name"
    values   = ["LTS"]
    match_by = "substring"
  }
  filter {
    key    = "type"
    values = ["base"]
  }
  sort {
    key       = "created"
    direction = "desc"
  }
}

data "cloudflare_zone" "kzwolenik" {
  name = var.apex-domain
}

resource "cloudflare_record" "kzwolenik" {
  zone_id = data.cloudflare_zone.kzwolenik.id
  name    = var.subdomain
  content = resource.digitalocean_droplet.web-server.ipv4_address
  type    = "A"
  proxied = true
}