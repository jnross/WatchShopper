
#include "items_window.h"
#include "commands.h"
#include "log.h"

static MenuLayer *items_menu;
static Window *items_window;

#define NUM_MENU_SECTIONS 2
#define SECTION_UNCHECKED 0
#define SECTION_CHECKED 1

static List *checklist;

static ListItem **unchecked_items = NULL;
static int unchecked_items_count = 0;
static ListItem **checked_items = NULL;
static int checked_items_count = 0;

static void discard_checklist();

static void refresh_checked_items() {
  if (checklist == NULL) { return; }
  if (checked_items == NULL) {
    checked_items = malloc(sizeof(ListItem *) * checklist->count);
  }
  if (unchecked_items == NULL) {
    unchecked_items = malloc(sizeof(ListItem *) * checklist->count);
  }

  unchecked_items_count = 0;
  checked_items_count = 0;

  for (int i = 0; i < checklist->count; i++) {
    ListItem *item = checklist->items[i];
    if (item->isChecked) {
      checked_items[checked_items_count++] = item;
    } else {
      unchecked_items[unchecked_items_count++] = item;
    }
  }
}

void reload_if_necessary() {
 	// Don't reload the menu until we've loaded all the items.  If we do, the app will crash when attempting to access bad memory.
 	if (checklist != NULL && checklist->count == checklist->expected_count) {
      refresh_checked_items();
    	menu_layer_reload_data(items_menu);
 	}
}

void parse_checklist_items_continuation(uint8_t *bytes, uint16_t length) {
	parse_list_items_continuation(checklist, bytes, length);
	reload_if_necessary();
}

void parse_checklist_items_start(uint8_t *bytes, uint16_t length) {
  if (items_window == NULL) {
    items_window = create_items_window();
    window_stack_push(items_window, true);
  }
	discard_checklist();
	checklist = parse_list_items_start(bytes, length);
	reload_if_necessary();
}

void parse_item_update(uint8_t *bytes) {
  uint8_t item_id = bytes[1];
  uint8_t flags = bytes[2];
  ListItem *item = checklist->items[item_id];
  item->isChecked = flags & 0x01;

  menu_layer_reload_data(items_menu);
}

void send_list_status() {
  if (checklist == NULL) return;
  int bufLength = 1 + 2 * checklist->count;
  uint8_t *buf = malloc(bufLength);
  int currentIndex = 0;
  buf[currentIndex++] = checklist->list_id;
  for (int i = 0; i < checklist->count; i++) {
    ListItem *item = checklist->items[i];
    buf[currentIndex++] = item->item_id;
    buf[currentIndex++] = item->isChecked ? FLAG_IS_CHECKED : 0;
  }

  DictionaryIterator *dict;
  app_message_outbox_begin(&dict);
  dict_write_data(dict, CMD_LIST_ITEM_UPDATE, buf, bufLength);

  app_message_outbox_send();
}

static void send_check_item(uint8_t list_id, uint8_t item_id, uint8_t flags) {
  uint8_t buf[3];
  buf[0] = list_id;
  buf[1] = item_id;
  buf[2] = flags;

  DictionaryIterator *dict;
  app_message_outbox_begin(&dict);
  dict_write_data(dict, CMD_LIST_ITEM_UPDATE, buf, 3);

  app_message_outbox_send();
}

// A callback is used to specify the amount of sections of menu items
// With this, you can dynamically add and remove sections
static uint16_t menu_get_num_sections_callback(MenuLayer *menu_layer, void *data) {
  return NUM_MENU_SECTIONS;
}

// Each section has a number of items;  we use a callback to specify this
// You can also dynamically add and remove items using this
static uint16_t menu_get_num_rows_callback(MenuLayer *menu_layer, uint16_t section_index, void *data) {
	if (checklist == NULL) {
		return 0;
	} else {
    if (section_index == SECTION_UNCHECKED) {
  		return unchecked_items_count;
    } else if (section_index == SECTION_CHECKED) {
      return checked_items_count;
    } else {
      return 0;
    }
	}
}

// A callback is used to specify the height of the section header
static int16_t menu_get_header_height_callback(MenuLayer *menu_layer, uint16_t section_index, void *data) {
  // This is a define provided in pebble_os.h that you may use for the default height
  if (section_index == 0) {
    return MENU_CELL_BASIC_HEADER_HEIGHT;
  } else {
    return 0;
  }
}

// A callback is used to specify the height of the section header
static int16_t menu_get_cell_height_callback(MenuLayer *menu_layer, MenuIndex *cell_index, void *callback_context) {
  // This is a define provided in pebble_os.h that you may use for the default height
  return 24;
}

// Here we draw what each header is
static void menu_draw_header_callback(GContext* ctx, const Layer *cell_layer, uint16_t section_index, void *data) {
  if (section_index == 0) {
    menu_cell_basic_header_draw(ctx, cell_layer, checklist->name);
  }
}

// This is the menu item draw callback where you specify what each item should look like
static void menu_draw_row_callback(GContext* ctx, const Layer *cell_layer, MenuIndex *cell_index, void *data) {
  ListItem *item = NULL;
  if (cell_index->section == SECTION_UNCHECKED) {
    item = unchecked_items[cell_index->row];
  } else if (cell_index->section == SECTION_CHECKED) {
    item = checked_items[cell_index->row];
  }

  if (item != NULL) {
    char* item_name = item->name;

    GFont font = fonts_get_system_font(FONT_KEY_GOTHIC_24_BOLD);
    GRect rect = (GRect){ .origin = GPointZero, .size = layer_get_frame(cell_layer).size };
    rect.origin.x += 2;
    rect.origin.y -= 4;
    rect.size.w -= 2;
    rect.size.h += 4;
    graphics_context_set_text_color(ctx, GColorBlack);
    graphics_draw_text(ctx, item_name, font, rect, GTextOverflowModeTrailingEllipsis, GTextAlignmentLeft, NULL);

    // Draw a line through checked items.
    if (item->isChecked) {
      graphics_context_set_fill_color(ctx, GColorBlack);
      GRect line_rect;
      line_rect.origin = (GPoint) {.x = 0, .y = (rect.size.h / 2) + 0};
      line_rect.size = (GSize) {.w = rect.size.w, .h = 2};
      graphics_fill_rect(ctx, line_rect, 0, GCornerNone);
    }

    return;
  }
}

// Here we capture when a user selects a menu item
void menu_select_callback(MenuLayer *menu_layer, MenuIndex *cell_index, void *data) {
  ListItem *item = NULL;
  if (cell_index->section == SECTION_UNCHECKED) {
    item = unchecked_items[cell_index->row];
  } else if (cell_index->section == SECTION_CHECKED) {
    item = checked_items[cell_index->row];
  }
  // Draw a line through newly-checked items.
  if (item->isChecked) {
    graphics_context_set_fill_color(ctx, GColorBlack);
    GRect line_rect;
    line_rect.origin = (GPoint) {.x = 0, .y = (rect.size.h / 2) + 0};
    line_rect.size = (GSize) {.w = rect.size.w, .h = 2};
    graphics_fill_rect(ctx, line_rect, 0, GCornerNone);
  }

  if (item != NULL) {
    item->isChecked = !(item->isChecked);
    send_check_item(checklist->list_id, item->item_id, item->isChecked);
    refresh_checked_items();
    menu_layer_reload_data(menu_layer);
  }

}

static void discard_checklist() {
  if (checklist != NULL) {
    list_destroy(checklist);
    checklist = NULL;
	}
  if (checked_items != NULL) {
    free(checked_items);
    checked_items = NULL;
  }
  if (unchecked_items != NULL) {
    free(unchecked_items);
    unchecked_items = NULL;
  }
}

static void items_window_load(Window *window) {
  checklist = NULL;
  Layer *window_layer = window_get_root_layer(window);
  GRect bounds = layer_get_frame(window_layer);
  bounds.origin = GPointZero;

  // Create the menu layer
  items_menu = menu_layer_create(bounds);
  
  // Set all the callbacks for the menu layer
  menu_layer_set_callbacks(items_menu, NULL, (MenuLayerCallbacks){
    .get_num_sections = menu_get_num_sections_callback,
    .get_num_rows = menu_get_num_rows_callback,
    .get_header_height = menu_get_header_height_callback,
    .get_cell_height = menu_get_cell_height_callback,
    .draw_header = menu_draw_header_callback,
    .draw_row = menu_draw_row_callback,
    .select_click = menu_select_callback,
  });

  // Bind the menu layer's click config provider to the window for interactivity
  menu_layer_set_click_config_onto_window(items_menu, window);

  // Add it to the window for display
  layer_add_child(window_layer, menu_layer_get_layer(items_menu));
  refresh_checked_items();
  menu_layer_reload_data(items_menu);

}

static void items_window_unload(Window *window) {
  menu_layer_destroy(items_menu);
  discard_checklist();
  if (items_window != NULL) {
    window_destroy(items_window);
    items_window = NULL;
  }
}

Window *create_items_window() {
	Window *window = window_create();
	window_set_window_handlers(window, (WindowHandlers) {
    	.load = items_window_load,
    	.unload = items_window_unload,
  	});
	return window;
}