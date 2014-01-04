WatchShopper

Allows you to sync your Evernote shopping lists to your Pebble watch so you can check things off as you shop.

Data format to Pebble

Checklist format
1. 1-byte list ID
2. null-terminated list title (UTF-8)
3. 1 byte for list length
4. Concatenated list items

Checklist item format
1. 1-byte item ID
2. null-terminated item title (UTF-8)
3. 1 byte for item flags
    0x01 - item is checked


Data format from Pebble

Check Item:
1. 1-byte action ID: 0x01 - check item
2. 1-byte list id
3. 1-byte item id


