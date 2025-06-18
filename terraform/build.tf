# terraform/build.tf
#
# Manages the local build process for the Lambda deployment package.

# Use a data source to hash all source files. This ensures a new zip
# is only created when code or dependencies change.
data "archive_file" "source_hash" {
  type        = "zip"
  output_path = "/dev/null" # We only care about the hash

  source {
    content  = file("${path.module}/../xml_to_json/handler.py")
    filename = "handler.py"
  }
  source {
    content  = file("${path.module}/../xml_to_json/requirements.txt")
    filename = "requirements.txt"
  }
}

# This resource runs the packaging commands locally.
# It only runs when the source file hash changes.
resource "null_resource" "build_lambda_package" {
  triggers = {
    source_hash = data.archive_file.source_hash.output_base64sha256
  }

  provisioner "local-exec" {
    command = <<-EOT
      rm -rf "${path.module}/.build" && mkdir -p "${path.module}/.build/dist"
      pip install -r "${path.module}/../xml_to_json/requirements.txt" -t "${path.module}/.build/dist"
      cp "${path.module}/../xml_to_json/handler.py" "${path.module}/.build/dist/"
    EOT
  }
}

# Creates the Lambda deployment package (.zip file) from the prepared directory.
resource "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/.build/dist"
  output_path = "${path.module}/.build/${var.service_name}.zip"

  # Explicit dependency ensures zipping happens after the build process completes.
  depends_on = [null_resource.build_lambda_package]
}