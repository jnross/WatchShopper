#include <pebble.h>

#include "items_window.h"
#include "checklists_window.h"
#include "commands.h"

static Window *window;

static void send_get_status() {
  uint8_t get_status = CMD_GET_STATUS;

  DictionaryIterator *dict;
  app_message_outbox_begin(&dict);
  dict_write_data(dict, CMD_GET_STATUS, &get_status, 1);

  app_message_outbox_send();
}

// App Message stuff.

void app_message_inbox_dropped(AppMessageResult reason, void *context) {

}

void app_message_inbox_received(DictionaryIterator *iterator, void *context) {
  Tuple *tuple = dict_read_first(iterator);

  if (tuple->key == CMD_LIST_ITEM_UPDATE) {
    parse_item_update(tuple->value->data);
  } else if (tuple->key == CMD_LIST_ITEMS_START) {
    parse_checklist_items_start(tuple->value->data, tuple->length);
  } else if (tuple->key == CMD_LIST_ITEMS_CONTINUATION) {
    parse_checklist_items_continuation(tuple->value->data, tuple->length);
  } else if (tuple->key == CMD_CHECKLISTS_START) {
    parse_checklists_start(tuple->value->data, tuple->length);
  } else if (tuple->key == CMD_CHECKLISTS_CONTINUATION) {
    parse_checklists_continuation(tuple->value->data, tuple->length);
  } else if (tuple->key == CMD_GET_LIST_STATUS) {
    APP_LOG(APP_LOG_LEVEL_DEBUG, "CMD_GET_LIST_STATUS");
    send_list_status();
  }

}

void app_message_outbox_failed(DictionaryIterator *iterator, AppMessageResult reason, void *context) {
  APP_LOG(APP_LOG_LEVEL_DEBUG, "app_message_outbox_failed: %d", reason);
  if (reason == APP_MSG_NOT_CONNECTED
    || reason == APP_MSG_APP_NOT_RUNNING
    || reason == APP_MSG_SEND_REJECTED
  )
  {
    // Notify app not connected.
    show_check_app_message(window);
  }

}

void app_message_outbox_sent(DictionaryIterator *iterator, void *context) {

}

static void init(void) {

  window = create_checklists_window();
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
