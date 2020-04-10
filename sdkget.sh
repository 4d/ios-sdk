#!/bin/sh

# parse sdk version file to checkout QMobile repo

version=$(cat sdkversion) # 18R2@19.1259d50.ce0af5a.798aef4.e3b6d7d

echo "version=$version"

branch=$(echo $version | sed 's/@.*//')
echo "branch=$branch"

notBranch=$(echo $version | sed 's/.*@//')

currentDir=$(pwd)
destination=Carthage/Checkouts

index=2
for name in QMobileAPI QMobileDataStore QMobileDataSync QMobileUI
do
    commit=$(echo $notBranch | cut -d '.' -f$index)
    echo "$name $commit"
    git clone https://gitlab-4d.private.4d.fr/qmobile/$name.git $destination/$name
    cd $destination/$name;git checkout -b $branch $commit;cd $currentDir
    index=$((index+1))
done

