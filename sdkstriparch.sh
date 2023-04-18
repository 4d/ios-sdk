#!/bin/bash   

# remove useless archs i386 armv7

frameworks_folder=Carthage/Build/iOS
archs="i386 armv7"
apples="apple-ios-simulator apple-ios"
swiftmodules="swiftdoc swiftmodule"

echo "🗑️ Removing useless architectures $archs"

for arch in $archs
do
  # echo "strip arch "$arch
  for framework in $frameworks_folder/*
  do
      if [[ -d $framework ]]; then
        filename=$(basename "$framework")
        name="${filename%.*}"
        extension="${framework##*.}"

        if [[ $extension = "framework" ]]; then

          file_path="$framework/$name"
          # echo " - strip framework "$name
          c=`lipo -info "$file_path" | grep $arch | wc -l`
          if [ $c = 1 ]; then
            lipo -remove $arch  "$file_path" -output "$file_path"
            echo "$arch stripped from $name"
          fi

          # swiftmodule
          for swiftmodule in $swiftmodules
          do
            file_path="$framework/Modules/$name.swiftmodule/$arch.$swiftmodule"
            if test -f $file_path; then
              echo "remove $file_path"
              rm -f $file_path
            fi

            for apple in $apples
            do
              file_path="$framework/Modules/$name.swiftmodule/$arch-$apple.$swiftmodule"
              if test -f $file_path; then
                echo "remove $file_path"
                rm -f $file_path
              fi
            done
          done

          # symbols
          file_path=$framework".dSYM/Contents/Resources/DWARF/$name"
          if [ -f "$file_path" ]; then
            # echo " - strip symbols "$name
            c=`lipo -info "$file_path" | grep $arch | wc -l`
            if [ $c = 1 ]; then
              lipo -remove $arch  "$file_path" -output "$file_path"
              echo "$arch stripped from symbols $name"
            fi
          fi
      fi
    fi
  done
done
