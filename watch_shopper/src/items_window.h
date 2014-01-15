
#include <pebble.h>

#include "list.h"

void parse_checklist_items_continuation(uint8_t *bytes, uint16_t length);
void parse_checklist_items_start(uint8_t *bytes, uint16_t length);
void parse_item_update(uint8_t *bytes);

void send_list_status();

Window *create_items_window();