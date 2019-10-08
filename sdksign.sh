nameCertificat=$1
Entitlements=$2
frameworks_folder=$3
if [ -z "$frameworks_folder" ]; then
	frameworks_folder="Carthage/Build/iOS"
fi
signApp=buildChain/SignApp.sh

# echo "strip arch "$arch
for framework in $frameworks_folder/*
do
    if [[ -d $framework ]]; then
      filename=$(basename "$framework")
      name="${filename%.*}"
      extension="${framework##*.}"

      if [[ $extension = "framework" ]]; then
	    # Sign symbol
        file_path=$framework".dSYM/Contents/Resources/DWARF/$name"
        if [ -f "$file_path" ]; then
           $signApp "$nameCertificat" "$file_path" "$Entitlements"
        fi
        
	    # Sign framework
        file_path="$framework"
        $signApp "$nameCertificat" "$file_path" "$Entitlements"
    fi
  fi
done
