
#include <pebble.h>

#include "list.h"

void parse_checklists_continuation(uint8_t *bytes, uint16_t length);
void parse_checklists_start(uint8_t *bytes, uint16_t length);

Window *create_checklists_window();

void show_check_app_message(Window *window);
void hide_check_app_message();
