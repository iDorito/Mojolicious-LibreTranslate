This project provides step-by-step instructions to set up a LibreTranslate virtual machine (VM) using Docker on a Linux system.

# lib_translate folder

This is a testing web with the basics for a translation from italian to 4 more languages.

# Run:

1. perl start_server.pl

# Steps

## VM Setup

1. **Create a new VM** in your preferred virtualization environment.
2. **Install a Linux distribution** (Ubuntu or Debian recommended) on the VM.
3. **Recommended VM specs:**
    - 2 GB RAM
    - 2 CPU cores
    - At least 16 GB storage (adjust as needed)

---

#### Commands made in the test VM (Ricardo) ####

1.      sudo apt update | sudo apt upgrade -y
2.      sudo apt install qemu-guest-agent -y
3.      sudo systemctl start qemu-guest-agent
4.      sudo systemctl enable qemu-guest-agent
5.      sudo apt instlal curl wget git ufw -y
6.      sudo apt install curl wget git ufw -y
7.      sudo ufw allow ssh
8.      sudo ufw allow 5000/tcp
9.      sudo ufw enable
10.     sudo ufw status
12.     sudo apt-get remove docker docker-engine docker.io containerd runc
13.     sudo apt install docker docker-engine docker.io containerd runc
14.     sudo apt-get update
15.     sudo apt-get install -y ca-certificates curl gnupg lsb-release
16.     sudo mkdir -p /etc/apt/keyrings
17.     curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
18.     echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
19.     sudo apt-get update
20.     sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
21.     sudo usermod -aG docker $USER
22.     newgrp docker
23.     docker run -d --name libretranslate -p 5000:5000 libretranslate/libretranslate
24.     curl -X POST "http://192.168.168.204:5000/translate"      -H "Content-Type: application/json"      -d '{"q": "Buon giorno", "source": "it", "target": "es"}'

# This commands should be enough to update the vm/linux, install docker, install libretranslate, open ports, run the docker and the libre translate, also a curl for testing.

### END ###

## Docker Setup

1. **Connect to your VM via SSH:**
     ```bash
     ssh your_username@IP_OF_THE_VM
     ```
2. **Update system packages:**
     ```bash
     sudo apt update
     sudo apt upgrade -y
     ```
3. **(Optional, for Proxmox or similar) Install `qemu-guest-agent`:**
     ```bash
     sudo apt install qemu-guest-agent -y
     sudo systemctl start qemu-guest-agent
     sudo systemctl enable qemu-guest-agent
     ```
     > Enables features like IP reporting in Proxmox.

4. **Install common utilities:**
     ```bash
     sudo apt install curl wget git ufw -y
     ```
     > `ufw` is a firewall utility; optional but recommended.

5. **(Optional) Configure the firewall:**
     ```bash
     sudo ufw allow ssh         # Allow SSH
     sudo ufw allow 5000/tcp    # Allow LibreTranslate port
     sudo ufw enable            # Enable firewall
     sudo ufw status
     ```

---

## Install Docker

1. **Remove any old Docker versions:**
     ```bash
     sudo apt-get remove docker docker-engine docker.io containerd runc
     ```
2. **Set up Docker's repository:**
     ```bash
     sudo apt-get update
     sudo apt-get install -y ca-certificates curl gnupg lsb-release
     sudo mkdir -p /etc/apt/keyrings
     # For Debian:
     curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
     # For Ubuntu:
     # curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
     ```
3. **Add Docker's repository:**
     ```bash
     # For Debian:
     echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
        $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
     # For Ubuntu:
     # echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
     ```
4. **Install Docker Engine:**
     ```bash
     sudo apt-get update
     sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
     ```
5. **Add your user to the `docker` group** (log out and back in to apply):
     ```bash
     sudo usermod -aG docker $USER
     newgrp docker
     ```

---

## Run LibreTranslate with Docker

Start LibreTranslate using the official Docker image:

```bash
docker run -d --name libretranslate \
     -p 5000:5000 \
     libretranslate/libretranslate:latest \
     --load-only "en,es,it,de,fr"
     # Optional flags:
     # --api-keys      # Enable API key usage
     # --update-models # Update models on startup
```

---

## Verify LibreTranslate is Running

- **Check the running container:**
     ```bash
     docker ps
     ```
- **View the container logs:**
     ```bash
     docker logs libretranslate
     ```

---

## Making Translation Queries (Perl/Mojolicious Example)

Below is a Perl/Mojolicious function to send translation requests to LibreTranslate.
This function is triggered after a button press and expects:

- Source text
- Source language code (e.g., `it`, `en`, `es`, `fr`)
- Target language code (e.g., `it`, `en`, `es`, `fr`)

```perl
sub process_translation {
     my $c = shift;

     my $source_text      = $c->param('source_text') // '';
     my $source_lang_code = lc($c->param('source_lang') // 'it'); # ensure lowercase
     my $target_lang_code = lc($c->param('target_lang') // 'en'); # ensure lowercase
     my $translated_text  = '';

     if ($source_text ne '' && $target_lang_code && $source_lang_code) {
          my $ua = Mojo::UserAgent->new;

          $c->app->log->debug("Query ready, trying to fetch query");

          try {
                # Make the POST request
                my $tx = $ua->post(
                     "http://192.168.168.204:5000/translate" =>
                     { 'Content-Type' => 'application/json' } =>
                     json => {
                          'q'      => $source_text,
                          'source' => $source_lang_code, # 'auto' is also an option if allowed
                          'target' => $target_lang_code
                     }
                );

                $c->app->log->debug("Query made");
                if ($tx->res->code == 200) {
                     my $res = $tx->res->json;
                     $translated_text = $res->{translatedText};
                }
          }
          catch {
                my $e = $_;
                $c->app->log->error("An exception occurred during LibreTranslate API call: $e");
          };

     } elsif ($source_text eq '') {
          $translated_text = "Por favor, ingresa texto para traducir.";
     } else {
          $translated_text = "Por favor, selecciona un idioma de origen y destino válidos.";
     }

     # Store in flash for persistence after redirect
     $c->flash(
          source_text          => $source_text,
          translated_text      => $translated_text,
          selected_source_lang => $source_lang_code,
          selected_target_lang => $target_lang_code,
     );

     $c->redirect_to('index_page');
}
```
