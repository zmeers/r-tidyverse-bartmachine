# Load libraries ----------------------------------------------------------

library(tidyverse)
library(analogsea)
library(broom)
library(rstanarm)
library(gapminder)
library(tictoc)
library(ggstance)
library(furrr)

# Path to private SSH key that matches key on DigitalOcean
ssh_private_key_file <- "~/.ssh/id_rsa"


# Set up remote machines --------------------------------------------------

# Create two new droplets with Docker pre-installed
# Here I'm using "s-4vcpu-8gb", which has 4 CPUs and 8 GB of RAM.
# Run analogsea::sizes() to see all the available sizes
analogsea::sizes()
droplet_image <- docklet_create(size = "s-4vcpu-8gb")

droplet_image_name <- droplet1[["name"]]

# Pull the docker image with the environment for this project

# NB: Wait for a minute before running this so that Docker is ready to
# run on the remote machines

# Get IP addresses
ip1 <- droplet(droplet_image$id)$networks$v4[[1]]$ip_address

# Run Dockerfile in terminal

# Power down instance
droplet(droplet_image$id) %>% droplet_power_off()

# Save snapshot

droplet(droplet_image$id) %>% droplet_snapshot()

# Update docker repo in terminal
