
nameCertificat=$1
Entitlements=$2
frameworks_folder=Carthage/Build/iOS
signApp=buildChain/SignApp.sh

# echo "strip arch "$arch
for framework in $frameworks_folder/*
do
    if [[ -d $framework ]]; then
      filename=$(basename "$framework")
      name="${filename%.*}"
      extension="${framework##*.}"

      if [[ $extension = "framework" ]]; then
        file_path=$framework".dSYM/Contents/Resources/DWARF/$name"
        if [ -f "$file_path" ]; then
           $signApp "$nameCertificat" "$file_path" "$Entitlements"
        fi
    fi
  fi
done
