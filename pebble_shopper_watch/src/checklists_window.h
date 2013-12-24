
#include <pebble.h>

#include "list.h"

#define CMD_CHECKLISTS_START 3
#define CMD_CHECKLISTS_CONTINUATION 4
#define CMD_CHECKLIST_SELECT 5

void parse_checklists_continuation(uint8_t *bytes, uint16_t length);
void parse_checklists_start(uint8_t *bytes, uint16_t length);

Window *create_checklists_window();