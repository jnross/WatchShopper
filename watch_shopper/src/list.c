#include "list.h"
#include "log.h"

List *list_create() {
  List* list = malloc(sizeof(List));
  MLOG("malloc %p", list);
  memset(list, 0, sizeof(List));
  return list;
}

void list_destroy(List *list) {
  if (list->name != NULL) {
    free(list->name);
    MLOG("free  %p", list->name);
    list->name = NULL;
  }
  if (list->items != NULL) {
    for (int i = 0; i < list->count; i++) {
      ListItem *item = list->items[i];
      if (item != NULL) {
        MLOG("free  %p", item->name);
        free(item->name);
        MLOG("free  %p", item);
        free(item);
        list->items[i] = NULL;
      }
    }
    free(list->items);
    MLOG("free  %p", list->items);
    list->items = NULL;
    list->count = 0;
  }
  free(list);
  MLOG("free  %p", list);
}

void parse_list_items_continuation(List *checklist, uint8_t *bytes, uint16_t length) {
  uint8_t current_index = 0;
  for (int i = 0; i < checklist->expected_count; i++ ){
    int item_index = bytes[current_index++];
    ListItem *item = malloc(sizeof(ListItem));
    MLOG("malloc %p", item);
    checklist->items[item_index] = item;
    item->item_id = item_index;
    char *name = (char *)&bytes[current_index];
    int name_length = strlen(name);
    char *item_name = malloc(name_length + 1);
    strncpy(item_name, name, name_length + 1);
    MLOG("malloc %p: %s", item_name, item_name);
    current_index += name_length + 1;
    item->name = item_name;
    int flags = bytes[current_index++];
    item->isChecked = (flags & 0x01) > 0;
    checklist->count = item_index + 1;

    if (current_index == length) {
      break;
    }
  }
}

List* parse_list_items_start(uint8_t *bytes, uint16_t length) {
  List *checklist = list_create();
  uint8_t current_index = 0;
  checklist->list_id = bytes[current_index++];
  char *name = (char *)&bytes[current_index];
  int namelength = strlen(name);
  checklist->name = malloc(namelength + 1);
  strncpy(checklist->name, name, namelength + 1);
  MLOG("malloc %p: %s", checklist->name, checklist->name);
  current_index += namelength + 1;
  checklist->count = 0;
  checklist->expected_count = bytes[current_index++];
  checklist->items = malloc(checklist->expected_count * sizeof(ListItem*));
  MLOG("malloc %p", checklist->items);
  memset(checklist->items, 0, checklist->expected_count * sizeof(ListItem*));

  parse_list_items_continuation(checklist, bytes + current_index, length - current_index);

  return checklist;
}