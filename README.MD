# Simple VM with OpenStack on Cleura Public Cloud

A small example of using [terraform](terraform.io/) with the [openstack
provider](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs)
on [Cleura public cloud](https://cleura.com/services/public-cloud/) to launch a
Debian VM with SSH access.

This declares the same resources as launching a VM through the web console would create.

# Dependencies

Recommended to use [nix](https://nixos.org/download.html) with
[direnv](https://direnv.net/) to provide the dependencies.

Otherwise, `terraform` is required.

# Usage

The direnv `.envrc` file will source `cloud.envrc` if it's present, which can
be a useful way to source the RC file for the `OS_` environment variables.

The commands for driving terraform are declared in a [just](https://just.systems/man/en/chapter_1.html) `justfile`.

These can be run with `just init` / `just apply` / `just destroy`.

