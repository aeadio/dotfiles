#!/bin/sh

# Check if ansible-playbook (and other deps?) installed
# If not,
  # Check if compatible Python installed?
    # If not, download a Python built to a temp dir
  # Download Ansible (and community plugins) to a temp dir
# Run Ansible on targets specified, default: 01-all.yml
