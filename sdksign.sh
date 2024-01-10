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

if [ -z "$frameworks_folder" ]; then
	frameworks_folder="Carthage/Build/iOS"
fi
signApp=./SignApp.sh

for framework in $frameworks_folder/*
do
  if [[ -d $framework ]]; then
    filename=$(basename "$framework")
    name="${filename%.*}"
    extension="${framework##*.}"

    if [[ $extension = "framework" ]]; then
      echo "📦 $name"
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
done
