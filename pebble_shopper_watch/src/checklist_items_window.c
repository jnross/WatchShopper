
#include "checklist_items_window.h"

typedef struct {
  uint8_t item_id;
  char *name;
  bool isChecked;
} CheckListItem;

static MenuLayer *items_menu;

#define NUM_MENU_SECTIONS 1

static uint8_t checklist_id;
static char *checklist_name;
static CheckListItem **checklist_items;
static uint8_t checklist_item_count;


void parse_list_items_continuation(uint8_t *bytes, uint16_t length) {
  uint8_t current_index = 0;
  uint8_t last_item_index = 0;
  for (int i = 0; i < checklist_item_count; i++ ){
    int item_id = bytes[current_index++];
    last_item_index = item_id;
    CheckListItem *item = malloc(sizeof(CheckListItem));
    checklist_items[item_id] = item;
    item->item_id = item_id;
    char *name = (char *)&bytes[current_index];
    int name_length = strlen(name);
    char *item_name = malloc(name_length + 1);
    strncpy(item_name, name, name_length);
    current_index += name_length + 1;
    item->name = item_name;
    int flags = bytes[current_index++];
    item->isChecked = (flags & 0x01) > 0;

    if (current_index == length) {
      break;
    }
  }

  // Don't reload the menu until we've loaded all the items.  If we do, the app will crash when attempting to access bad memory.
  if (last_item_index == checklist_item_count - 1) {
    APP_LOG(APP_LOG_LEVEL_DEBUG, "reloading menu");
    menu_layer_reload_data(items_menu);
  }
}

void parse_list_items_start(uint8_t *bytes, uint16_t length) {
  uint8_t current_index = 0;
  checklist_id = bytes[current_index++];
  char *name = (char *)&bytes[current_index];
  int namelength = strlen(name);
  checklist_name = malloc(namelength + 1);
  strncpy(checklist_name, name, namelength);
  current_index += namelength + 1;
  checklist_item_count = bytes[current_index++];
  checklist_items = malloc(checklist_item_count * sizeof(CheckListItem*));
  memset(checklist_items, 0, checklist_item_count * sizeof(CheckListItem*));

  parse_list_items_continuation(bytes + current_index, length - current_index);
}

void parse_item_update(uint8_t *bytes) {
  uint8_t item_id = bytes[1];
  uint8_t flags = bytes[2];
  CheckListItem *item = checklist_items[item_id];
  item->isChecked = flags & 0x01;

  menu_layer_reload_data(items_menu);
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
  return checklist_item_count;
}

// A callback is used to specify the height of the section header
static int16_t menu_get_header_height_callback(MenuLayer *menu_layer, uint16_t section_index, void *data) {
  // This is a define provided in pebble_os.h that you may use for the default height
  return MENU_CELL_BASIC_HEADER_HEIGHT;
}

// A callback is used to specify the height of the section header
static int16_t menu_get_cell_height_callback(MenuLayer *menu_layer, MenuIndex *cell_index, void *callback_context) {
  // This is a define provided in pebble_os.h that you may use for the default height
  return 24;
}

// Here we draw what each header is
static void menu_draw_header_callback(GContext* ctx, const Layer *cell_layer, uint16_t section_index, void *data) {
  menu_cell_basic_header_draw(ctx, cell_layer, checklist_name);
}

// This is the menu item draw callback where you specify what each item should look like
static void menu_draw_row_callback(GContext* ctx, const Layer *cell_layer, MenuIndex *cell_index, void *data) {
  if (cell_index->row < checklist_item_count) {
    CheckListItem *item = checklist_items[cell_index->row];
    char* item_name = item->name;

    GFont font = fonts_get_system_font(FONT_KEY_GOTHIC_24_BOLD);
    GRect rect = (GRect){ .origin = GPointZero, .size = layer_get_frame(cell_layer).size };
    rect.origin.x += 2;
    rect.origin.y -= 4;
    rect.size.w -= 2;
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
  CheckListItem *item = checklist_items[cell_index->row];
  item->isChecked = !(item->isChecked);
  send_check_item(checklist_id, item->item_id, item->isChecked);
  menu_layer_reload_data(menu_layer);

}

static void discard_checklist_items() {
	if (checklist_name != NULL) {
		free(checklist_name);
		checklist_name = NULL;
	}
	if (checklist_items != NULL) {
		for (int i = 0; i < checklist_item_count; i++) {
			CheckListItem *item = checklist_items[i];
			if (item != NULL) {
				free(item);
				checklist_items[i] = NULL;
			}
		}
		free(checklist_items);
		checklist_items = NULL;
		checklist_item_count = 0;
	}
}

static void checklist_items_window_load(Window *window) {
  checklist_items = NULL;
  checklist_item_count = 0;
  checklist_name = NULL;
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
  menu_layer_reload_data(items_menu);


  APP_LOG(APP_LOG_LEVEL_DEBUG, "Added menu %p to window", items_menu);
}

static void checklist_items_window_unload(Window *window) {
	menu_layer_destroy(items_menu);
}

Window *create_checklist_items_window() {
	Window *window = window_create();
	window_set_window_handlers(window, (WindowHandlers) {
    	.load = checklist_items_window_load,
    	.unload = checklist_items_window_unload,
  	});
	return window;
}