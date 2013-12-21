
#include <pebble.h>

#define CMD_LIST_ITEMS_START 0
#define CMD_LIST_ITEM_UPDATE 1
#define CMD_LIST_ITEMS_CONTINUATION 2

void parse_list_items_continuation(uint8_t *bytes, uint16_t length);
void parse_list_items_start(uint8_t *bytes, uint16_t length);
void parse_item_update(uint8_t *bytes);

Window *create_checklist_items_window();