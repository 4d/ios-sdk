
file=Cartfile.resolved

github=$(grep github $file)


github=$(echo "${github//github /https://www.github.com/}")

github=$(echo $github| sed s/\"//g)

github=$(echo $github | grep github )

for url in $github
do
    url=$(echo $url | grep github )
    if [ -n "${url}" ]; then
      echo "$url"
      #git clone $url
      #cd ${url##*/}
      open "$url"
            #git remote rename origin upstream
      #hub fork --org QuatreiOS
    fi
done
