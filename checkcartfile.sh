#!/bin/bash   

# Fix CocoaPods ie. SDK Cartfile.resolved file
cd ..
file=CocoaPods/Cartfile.resolved
url=https://gitlab-4d.private.4d.fr/qmobile/ios/
alternative=~/QMobile # alernative parent path if the repo are not git repo

sed -i '' '/QMobile/d' $file # remove QMobile form file

## Inject last QMobile hash
for f in QMobile*; do
 	hash=`git -C $f rev-parse HEAD > /dev/null 2>&1`
    retval=$?
 	if [ $retval -ne 0 ]; then
 	   hash=`git -C $alternative/$f rev-parse HEAD` # use alternative path if failed
    fi
    line="git \"$url$f.git\" \"$hash\""

    echo "$line" >> "$file"
done

# Fix QMobile  Cartfile.resolved file using values from SDK file
for d in QMobile*/ ; do

	if [ -f "$d/Cartfile.resolved" ]; then

       content=`cat "$d/Cartfile.resolved"`
	 
	   newfile="$d/Cartfile.resolved" # in place
       > "$newfile"

       while IFS= read -r line ; do
        item=`echo "$line" | cut -d " " -f 2` # take the project 

        line=`cat $file | grep $item` # get in sdk file

        echo "$line" >> "$newfile"

       done <<< "$content"

    fi

done
