module "vpc" {
    source = "terraform-aws-modules/vpc/aws"

    name = "${var.project_name}-vpc"
    cidr = var.vpc_cidr

    azs = local.availability_zones

    public_subnets  = local.public_subnet_cidrs
    public_subnet_names = local.public_subnet_names
    map_public_ip_on_launch = true

    private_subnets = local.private_subnet_cidrs
    private_subnet_names = local.private_subnet_names

    create_database_subnet_group = true

    enable_nat_gateway = true
    single_nat_gateway = false
    one_nat_gateway_per_az = true

    enable_dns_hostnames = true
    enable_dns_support   = true
}


