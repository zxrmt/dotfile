ID="#SHORTCUTID"

curl -fsSL \
  "https://www.icloud.com/shortcuts/api/records/$ID" \
  -o record.json

URL=$(plutil -extract fields.shortcut.value.downloadURL raw -o - record.json)

URL="${URL//'${f}'/shortcut.plist}"

curl -fsSL "$URL" -o translate.plist

plutil -convert xml1 translate.plist
