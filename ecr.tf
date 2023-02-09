resource "aws_ecr_repository" "jux_consumer_web_repo" {
  count                = var.environment == "dev" ? 1 : 0
  provider             = aws.toolsaccount
  name                 = "${var.projectname}-backend"
  image_tag_mutability = "MUTABLE"
  tags                 = var.tags
}
