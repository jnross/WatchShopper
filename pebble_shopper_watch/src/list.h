#pragma once

#include <pebble.h>

typedef struct {
  uint8_t item_id;
  char *name;
  bool isChecked;
} ListItem;

typedef struct {
  uint8_t list_id;
  char *name;
  ListItem **items;
  uint8_t count;
  uint8_t expected_count;
} List;

List* list_create();
void list_destroy(List *list);

void parse_list_items_continuation(List *list, uint8_t *bytes, uint16_t length);
List* parse_list_items_start(uint8_t *bytes, uint16_t length);
