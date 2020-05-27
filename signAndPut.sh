#!/bin/sh
uploadDir=$1
originIPAFile="origin.ipa"
configureFile="idFile"
originPlistFile="origin.plist"
dateWithTime=`date "+%Y%m%d-%H%M%S"`
outputDir="output${dateWithTime}"

# 创建输出目录。
mkdir $outputDir

unzip "$originIPAFile"

cp embedded.mobileprovision Payload/*.app/embedded.mobileprovision
security cms -D -i Payload/*.app/embedded.mobileprovision > provisioning.plist
/usr/libexec/PlistBuddy -x -c 'Print:Entitlements' "provisioning.plist" > "entitlements.plist"

while IFS= read -r line
do
	IFS=',' read -r -a lineToken <<< "$line"
	# plist 和 ipa 文件名。
	fileName=$(echo "${lineToken[0]}" | tr -d '[:space:][:blank:]')
	channelID=$(echo "${lineToken[1]}" | tr -d '[:space:][:blank:]')
	echo "fileName = \"${fileName}\", channelID = \"${channelID}\""

	# 写入渠道 ID。
	sed -i -e -E "s/\"id\":.+/\"id\":$channelID,/g" Payload/*.app/res/channel.json
	rm -rf Payload/*.app/res/channel.json-e

	rm -rf Payload/*.app/_CodeSignature/
	# 重新签名。
	codesign --entitlements entitlements.plist -f -s "iPhone Distribution: Wuhan Windoor Information &Technology Co., Ltd." -v Payload/*.app

	#重新打包。
	ipaFileName="${fileName}.ipa"
	ipaFilePath="${outputDir}/${ipaFileName}"
	zip -qr "${ipaFilePath}" Payload/
	
	# 复制模版plist文件到输出目录，替换 ipa 路径为指定路径。
	plistFileName="${fileName}.plist"
	plistFilePath="${outputDir}/${plistFileName}"
	cp "${originPlistFile}" "${plistFilePath}"
	plistIPAFilePath="${uploadDir}\/${ipaFileName}"
	sed -i -e -E "s/game.+\.ipa/${plistIPAFilePath}/g" "${plistFilePath}"
	rm -rf "${plistFilePath}-e"

done < "$configureFile"

rm -rf __MACOSX
rm -rf Payload