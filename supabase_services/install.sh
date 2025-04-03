#!/bin/bash

# Hanbok Supabase Services Installation Script
# This script clones the repository and runs setup_script.sh

# Display usage information
show_usage() {
  echo "Hanbok Supabase Services Installer"
  echo "Usage: ./install.sh <flutter_project_path>"
  echo ""
  echo "This script will:"
  echo "1. Clone the hanbok_supabaseServices repository"
  echo "2. Run the setup script to integrate with your Flutter project"
  echo ""
  echo "Example:"
  echo "  ./install.sh /path/to/my_flutter_app"
}

# Check if argument is provided
if [ -z "$1" ]; then
  show_usage
  exit 1
fi

TARGET_DIR="$1"

# Check if target directory exists
if [ ! -d "$TARGET_DIR" ]; then
  echo "Error: Target directory does not exist."
  echo "Please create a Flutter project first with: flutter create my_new_project"
  exit 1
fi

# Confirm the target directory is a Flutter project
if [ ! -f "$TARGET_DIR/pubspec.yaml" ]; then
  echo "Error: Target directory does not appear to be a Flutter project."
  echo "pubspec.yaml not found in $TARGET_DIR"
  exit 1
fi

# Create a temporary directory
TEMP_DIR=$(mktemp -d)
echo "Creating temporary directory: $TEMP_DIR"

# Clone the repository
echo "Cloning hanbok_supabaseServices repository..."
git clone https://github.com/seungboAn/hanbok_supabaseServices.git "$TEMP_DIR"

if [ $? -ne 0 ]; then
  echo "Error: Failed to clone the repository."
  exit 1
fi

# Run the setup script
echo "Running setup script..."
cd "$TEMP_DIR"
./setup_script.sh "$TARGET_DIR"

if [ $? -ne 0 ]; then
  echo "Error: Setup script failed."
  exit 1
fi

# Clean up
echo "Cleaning up temporary files..."
cd - > /dev/null
rm -rf "$TEMP_DIR"

echo ""
echo "Installation completed successfully!"
echo ""
echo "Next steps:"
echo "1. Edit $TARGET_DIR/.env with your Supabase credentials"
echo "2. Run 'flutter pub get' in your new project directory"
echo "3. Try the example code in $TARGET_DIR/lib/examples/supabase_example.dart"
echo ""
echo "For more information, see the documentation at:"
echo "https://github.com/seungboAn/hanbok_supabaseServices" 