#include <pebble.h>

#include "checklist_items_window.h"

static Window *window;

#define CMD_GET_STATUS 3

static void send_get_status() {
  uint8_t get_status = 3;

  DictionaryIterator *dict;
  app_message_outbox_begin(&dict);
  dict_write_data(dict, CMD_GET_STATUS, &get_status, 1);

  app_message_outbox_send();
}


// App Message stuff.

void app_message_inbox_dropped(AppMessageResult reason, void *context) {

}

void app_message_inbox_received(DictionaryIterator *iterator, void *context) {
  APP_LOG(APP_LOG_LEVEL_DEBUG, "Received app message");
  Tuple *tuple = dict_read_first(iterator);

  if (tuple->key == CMD_LIST_ITEMS_START) {
    parse_checklist_items_start(tuple->value->data, tuple->length);
  } else if (tuple->key == CMD_LIST_ITEM_UPDATE) {
    parse_item_update(tuple->value->data);
  } else if (tuple->key == CMD_LIST_ITEMS_CONTINUATION) {
    parse_checklist_items_continuation(tuple->value->data, tuple->length);
  }
  

}

void app_message_outbox_failed(DictionaryIterator *iterator, AppMessageResult reason, void *context) {

}

void app_message_outbox_sent(DictionaryIterator *iterator, void *context) {

}

static void init(void) {

  window = create_checklist_items_window();
  const bool animated = true;
  window_stack_push(window, animated);

  app_message_open(/*inbound*/124, /*outbound*/32);
  app_message_register_inbox_dropped(app_message_inbox_dropped);
  app_message_register_inbox_received(app_message_inbox_received);
  app_message_register_outbox_failed(app_message_outbox_failed);
  app_message_register_outbox_sent(app_message_outbox_sent);

  send_get_status();

}

static void deinit(void) {

  window_destroy(window);
}

int main(void) {
  init();

  APP_LOG(APP_LOG_LEVEL_DEBUG, "Done initializing, pushed window: %p", window);

  app_event_loop();
  deinit();
}
