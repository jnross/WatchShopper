
#include "checklist_items_window.h"

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
} List;

static MenuLayer *items_menu;

#define NUM_MENU_SECTIONS 1

static List *checklist;

static void discard_checklist();

void list_destroy(List *list);
List* list_create();

void parse_list_items_continuation(uint8_t *bytes, uint16_t length) {
  uint8_t current_index = 0;
  uint8_t last_item_index = 0;
  for (int i = 0; i < checklist->count; i++ ){
    int item_id = bytes[current_index++];
    last_item_index = item_id;
    ListItem *item = malloc(sizeof(ListItem));
    checklist->items[item_id] = item;
    item->item_id = item_id;
    char *name = (char *)&bytes[current_index];
    int name_length = strlen(name);
    char *item_name = malloc(name_length + 1);
    APP_LOG(APP_LOG_LEVEL_DEBUG, "malloc %p", item_name);
    strncpy(item_name, name, name_length);
    //APP_LOG(APP_LOG_LEVEL_DEBUG, "Item %s", item_name);
    current_index += name_length + 1;
    item->name = item_name;
    int flags = bytes[current_index++];
    item->isChecked = (flags & 0x01) > 0;

    if (current_index == length) {
      break;
    }
  }

  // Don't reload the menu until we've loaded all the items.  If we do, the app will crash when attempting to access bad memory.
  if (last_item_index == checklist->count - 1) {
    APP_LOG(APP_LOG_LEVEL_DEBUG, "reloading menu");
    menu_layer_reload_data(items_menu);
  }
}

List *list_create() {
    APP_LOG(APP_LOG_LEVEL_DEBUG, "list_create");
	List* list = malloc(sizeof(List));
	memset(list, 0, sizeof(List));
	return list;
}

void parse_list_items_start(uint8_t *bytes, uint16_t length) {
  discard_checklist();
  checklist = list_create();
  uint8_t current_index = 0;
  checklist->list_id = bytes[current_index++];
  char *name = (char *)&bytes[current_index];
  int namelength = strlen(name);
  checklist->name = malloc(namelength + 1);
  strncpy(checklist->name, name, namelength);
  current_index += namelength + 1;
  checklist->count = bytes[current_index++];
  checklist->items = malloc(checklist->count * sizeof(ListItem*));
  memset(checklist->items, 0, checklist->count * sizeof(ListItem*));

  parse_list_items_continuation(bytes + current_index, length - current_index);
}

void parse_item_update(uint8_t *bytes) {
  uint8_t item_id = bytes[1];
  uint8_t flags = bytes[2];
  ListItem *item = checklist->items[item_id];
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
	if (checklist == NULL) {
		return 0;
	} else {
  		return checklist->count;
	}
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
  menu_cell_basic_header_draw(ctx, cell_layer, checklist->name);
}

// This is the menu item draw callback where you specify what each item should look like
static void menu_draw_row_callback(GContext* ctx, const Layer *cell_layer, MenuIndex *cell_index, void *data) {
  if (cell_index->row < checklist->count) {
    ListItem *item = checklist->items[cell_index->row];
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
  ListItem *item = checklist->items[cell_index->row];
  item->isChecked = !(item->isChecked);
  send_check_item(checklist->list_id, item->item_id, item->isChecked);
  menu_layer_reload_data(menu_layer);

}

static void discard_checklist() {
    APP_LOG(APP_LOG_LEVEL_DEBUG, "discard_checklist");
    if (checklist != NULL) {
    	list_destroy(checklist);
    	checklist = NULL;
	}
}

void list_destroy(List *list) {
	if (list->name != NULL) {
		free(list->name);
		list->name = NULL;
	}
	if (list->items != NULL) {
		for (int i = 0; i < list->count; i++) {
			ListItem *item = list->items[i];
			if (item != NULL) {
    			APP_LOG(APP_LOG_LEVEL_DEBUG, "free  %p", item->name);
				free(item->name);
    			APP_LOG(APP_LOG_LEVEL_DEBUG, "free  %p", item);
				free(item);
				list->items[i] = NULL;
			}
		}
		free(list->items);
		list->items = NULL;
		list->count = 0;
	}
	free(list);
}

static void checklist_items_window_load(Window *window) {
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
  menu_layer_reload_data(items_menu);


  APP_LOG(APP_LOG_LEVEL_DEBUG, "Added menu %p to window", items_menu);
}

static void checklist_items_window_unload(Window *window) {
	discard_checklist();
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