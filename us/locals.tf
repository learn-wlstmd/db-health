locals {
    availability_cidr_blocks = [
        for i in range(0, 255) : cidrsubnet(var.vpc_cidr, 8, i)
    ]

    public_subnet_cidrs = [
        for i in range(0, length(var.public_subnet_cidrs)) : local.availability_cidr_blocks[var.public_subnet_cidrs[i]]
    ]

    private_subnet_cidrs = [
        for i in range(0, length(var.private_subnet_cidrs)) : local.availability_cidr_blocks[var.private_subnet_cidrs[i]]
    ]

    availability_zones = [for az in var.availability_zones : "${var.region}${az}"]

    public_subnet_names = [for i in range(0, length(var.public_subnet_cidrs)) : "${var.project_name}-public-${var.availability_zones[i]}"]
    private_subnet_names = [for i in range(0, length(var.private_subnet_cidrs)) : "${var.project_name}-private-${var.availability_zones[i]}"]
}
