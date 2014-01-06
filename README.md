WatchShopper
============

Allows you to sync your Evernote shopping lists to your Pebble watch so you can check things off as you shop.

App Message IDs
---------------
To Watch:
<table>
  <tr>
    <th>ID</th><th>Name</th><th>Description</th>
  </tr>
  <tr>
    <td>0x00</td><td>CMD_LIST_ITEMS_START</td><td></td>
  </tr>
  <tr>
    <td>0x01</td><td>CMD_LIST_ITEMS_CONTINUATION</td><td></td>
  </tr>
  <tr>
    <td>0x10</td><td>CMD_CHECKLISTS_START</td><td></td>
  </tr>
  <tr>
    <td>0x11</td><td>CMD_CHECKLISTS_CONTINUATION</td><td></td>
  </tr>
  <tr>
    <td>0x20</td><td>CMD_LIST_ITEM_UPDATE</td><td></td>
  </tr>
</table>
From Watch:
<table>
  <tr>
    <th>ID</th><th>Name</th><th>Description</th>
  </tr>
  <tr>
    <td>0x80</td><td>CMD_GET_STATUS</td><td></td>
  </tr>
  <tr>
    <td>0x81</td><td>CMD_CHECKLIST_SELECT</td><td></td>
  </tr>
</table>

App Message Formats
-------------------

Checklist format

1.  1-byte list ID
2.  null-terminated list title (UTF-8)
3.  1 byte for list length
4.  Concatenated list items

Checklist item format

1.  1-byte item ID
2.  null-terminated item title (UTF-8)
3.  1 byte for item flags
    * 0x01 - item is checked

Update Item:

1.  1-byte action ID: 0x01 - check item
2.  1-byte list id
3.  1-byte item id
