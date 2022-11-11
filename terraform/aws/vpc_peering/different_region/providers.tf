provider "aws" {
  region = var.source_region
}

provider "aws" {
  alias  = "destination"
  region = var.destination_region
}
