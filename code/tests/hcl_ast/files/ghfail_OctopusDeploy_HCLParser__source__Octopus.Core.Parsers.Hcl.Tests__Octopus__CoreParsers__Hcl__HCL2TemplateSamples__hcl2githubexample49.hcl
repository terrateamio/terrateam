resource "aws_codebuild_project" "codepipeline_plan_project" {


  tags = {

    "Environment" = var.environment
    "Project"     = "${var.name_prefix}-${var.name_suffix}-${var.environment}"

  }
}

