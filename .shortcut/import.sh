# Validate XML
plutil -lint translate.plist

# Convert to binary plist
plutil -convert binary1 \
  -o translate-unsigned.shortcut translate.plist

# Sign shortcut
shortcuts sign \
  --mode anyone \
  --input translate-unsigned.shortcut \
  --output translate.shortcut

# Import
open translate.shortcut
