#!/bin/bash

# Setup script for Supabase Services package
# Usage: ./setup_script.sh path_to_new_flutter_project

# Check if argument is provided
if [ -z "$1" ]; then
  echo "Usage: ./setup_script.sh path_to_new_flutter_project"
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

# Copy the Supabase Services package to the target project
echo "Copying Supabase Services package to $TARGET_DIR/supabase_services..."
mkdir -p "$TARGET_DIR/supabase_services"
cp -r ./* "$TARGET_DIR/supabase_services/"

# Create .env file
echo "Creating .env file in $TARGET_DIR..."
cp .env.example "$TARGET_DIR/.env"
echo "Please edit $TARGET_DIR/.env with your Supabase credentials."

# Update the target project's pubspec.yaml
echo "Updating target project's pubspec.yaml..."
cat >> "$TARGET_DIR/pubspec.yaml" << EOF

  # Added by Supabase Services setup script
  supabase_services:
    path: ./supabase_services
  flutter_dotenv: ^5.1.0
EOF

echo "Adding .env to assets..."
# Check if assets section exists
if grep -q "assets:" "$TARGET_DIR/pubspec.yaml"; then
  # Add .env to existing assets section
  sed -i '' -e '/assets:/,/^[^ ]/ s/$/\n    - .env/' "$TARGET_DIR/pubspec.yaml"
else
  # Add new assets section
  cat >> "$TARGET_DIR/pubspec.yaml" << EOF

flutter:
  assets:
    - .env
EOF
fi

# Create example code
echo "Creating example code..."
mkdir -p "$TARGET_DIR/lib/examples"
cp example_usage.dart "$TARGET_DIR/lib/examples/supabase_example.dart"

# Create initialization code in main.dart
echo "Adding Supabase initialization to main.dart..."
MAIN_FILE="$TARGET_DIR/lib/main.dart"
BACKUP_FILE="$TARGET_DIR/lib/main.dart.bak"

# Backup original main.dart
cp "$MAIN_FILE" "$BACKUP_FILE"

# Add Supabase initialization
sed -i '' -e 's/import .*/import '\''package:flutter\/material.dart'\''\;\nimport '\''package:supabase_services\/supabase_services.dart'\'';/' "$MAIN_FILE"
sed -i '' -e 's/void main() {/void main() async {\n  WidgetsFlutterBinding.ensureInitialized();\n\n  \/\/ Initialize Supabase services\n  await SupabaseServices.initialize();\n/' "$MAIN_FILE"

echo "Setup completed successfully!"
echo ""
echo "Next steps:"
echo "1. Edit $TARGET_DIR/.env with your Supabase credentials"
echo "2. Run 'flutter pub get' in your new project directory"
echo "3. See example code in $TARGET_DIR/lib/examples/supabase_example.dart"
echo "4. See integration guide in $TARGET_DIR/supabase_services/INTEGRATION.md"
echo ""
echo "Happy coding!" 