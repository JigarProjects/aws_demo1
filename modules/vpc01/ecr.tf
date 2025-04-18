resource "aws_ecr_repository" "vote-frontend" {
    name                 = "vote-frontend"
    image_tag_mutability = "MUTABLE"
    tags = {
        Name = "vote-frontend"
    }
}
resource "aws_ecr_repository" "vote-api" {
    name                 = "vote-api"
    image_tag_mutability = "MUTABLE"
    tags = {
        Name = "vote-api"
    }
}
