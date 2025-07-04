# terraform/build.tf
#
# Manages the local build process for the Lambda deployment package.

resource "null_resource" "build_lambda_package" {
  triggers = {
    source_code_hash = filebase64sha256("${path.module}/../xml_to_json/handler.py")
  }

  # --- THIS BLOCK IS UPDATED FOR WINDOWS POWERSHELL ---
  provisioner "local-exec" {
    # Specify PowerShell as the interpreter for these commands.
    interpreter = ["PowerShell", "-Command"]
    
    command = <<-EOT
      # 1. Remove the old build directory if it exists. -Recurse and -Force ensure it's deleted.
      if (Test-Path -Path "${path.module}/.build") { Remove-Item -Recurse -Force "${path.module}/.build" }
      
      # 2. Create the new distribution directory.
      New-Item -ItemType Directory -Force -Path "${path.module}/.build/dist"
      
      # 3. Install Python requirements into the new directory.
      pip install -r "${path.module}/../xml_to_json/requirements.txt" -t "${path.module}/.build/dist"
      
      # 4. Copy the handler script into the directory.
      Copy-Item -Path "${path.module}/../xml_to_json/handler.py" -Destination "${path.module}/.build/dist/"
      
      # 5. Create the zip file from the contents of the 'dist' directory.
      Compress-Archive -Path "${path.module}/.build/dist/*" -DestinationPath "${path.module}/${var.service_name}.zip" -Force
    EOT
  }
}