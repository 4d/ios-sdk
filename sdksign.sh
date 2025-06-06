#!/bin/bash

nameCertificat=$1
Entitlements=$2
frameworks_folder=$3

# fill with default values
if [ -z "$nameCertificat" ]; then
	nameCertificat="Developer ID Application"
fi

if [ -z "$Entitlements" ]; then
	Entitlements="SDK.entitlements"
fi

frameworks_extension="framework"

if [ -z "$frameworks_folder" ]; then

  frameworks_folder="Carthage/Build/iOS"
  
  if [[ -d "$frameworks_folder" ]]; then
    echo "Found: $frameworks_folder"
  else
    if [[ -z "${USE_XCFRAMEWORKS}" ]]; then
      frameworks_folder=$3
      USE_XCFRAMEWORKS=1
    fi
  fi
fi

if [ "$USE_XCFRAMEWORKS" -eq 1 ]; then
  frameworks_extension="xcframework"
  if [ -z "$frameworks_folder" ]; then
    frameworks_folder="Carthage/Build"
  fi
fi

signApp=./SignApp.sh

for framework in $frameworks_folder/*
do
  if [[ -d $framework ]]; then
    filename=$(basename "$framework")
    name="${filename%.*}"
    extension="${framework##*.}"

    if [[ $extension = "$frameworks_extension" ]]; then
      echo "📦 $name"

      if [ "$USE_XCFRAMEWORKS" -eq 1 ]; then
        # For XCFrameworks, iterate through platform-specific folders
        for platform_folder in "$framework"/*; do
          if [[ -d "$platform_folder" ]]; then
            platform_name=$(basename "$platform_folder")
            
            # Skip Info.plist and other non-directory files
            if [[ "$platform_name" != "Info.plist" ]]; then
              echo "  🔨 Platform: $platform_name"
              
              # Sign the .framework inside the platform folder
              framework_path="$platform_folder/$name.framework"
              if [[ -d "$framework_path" ]]; then
                echo "    📁 Signing framework: $framework_path"
                $signApp "$nameCertificat" "$framework_path" "$Entitlements"
              fi
              
              # Sign the dSYM files if they exist
              dsym_folder="$platform_folder/dSYMs"
              if [[ -d "$dsym_folder" ]]; then
                for dsym in "$dsym_folder"/*.dSYM; do
                  if [[ -d "$dsym" ]]; then
                    dsym_file="$dsym/Contents/Resources/DWARF/$name"
                    if [[ -f "$dsym_file" ]]; then
                      echo "    🔍 Signing dSYM: $dsym_file"
                      $signApp "$nameCertificat" "$dsym_file" "$Entitlements"
                    fi
                  fi
                done
              fi
            fi
          fi
        done
        echo ""
      else
        # Sign symbol
        file_path=$framework".dSYM/Contents/Resources/DWARF/$name"
        if [ -f "$file_path" ]; then
            $signApp "$nameCertificat" "$file_path" "$Entitlements"
        fi
        
        # Sign framework
        file_path="$framework"
        $signApp "$nameCertificat" "$file_path" "$Entitlements"
        echo ""
      fi
    fi
  fi
done
