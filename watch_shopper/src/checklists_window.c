
#include "checklists_window.h"
#include "commands.h"
#include "log.h"

static MenuLayer *checklists_menu;
static TextLayer *message_text = NULL;

#define NUM_MENU_SECTIONS 1

static List *checklists;

static void discard_checklists();

static void reload_if_necessary() {
 	// Don't reload the menu until we've loaded all the items.  If we do, the app will crash when attempting to access bad memory.
 	if (checklists->count == checklists->expected_count) {
    	menu_layer_reload_data(checklists_menu);
      // Bind the menu layer's click config provider to the window for interactivity
      Window *window = layer_get_window(menu_layer_get_layer(checklists_menu));
      menu_layer_set_click_config_onto_window(checklists_menu, window);
 	}
}

void parse_checklists_continuation(uint8_t *bytes, uint16_t length) {
	parse_list_items_continuation(checklists, bytes, length);
	reload_if_necessary();
}

void parse_checklists_start(uint8_t *bytes, uint16_t length) {
  hide_check_app_message();
	discard_checklists();
	checklists = parse_list_items_start(bytes, length);
	reload_if_necessary();
}

void show_check_app_message(Window *window) {
  if (message_text == NULL) {
    Layer *window_layer = window_get_root_layer(window);
    GRect bounds = layer_get_bounds(window_layer);
    bounds.origin.y = 30;
    bounds.size.h -= 2 * bounds.origin.y;
    message_text = text_layer_create(bounds);
    GFont *font = fonts_get_system_font(FONT_KEY_GOTHIC_28_BOLD);
    text_layer_set_font(message_text, font);
    text_layer_set_text_alignment(message_text, GTextAlignmentCenter);
    text_layer_set_text(message_text, "Please activate WatchShopper on your phone");
    layer_add_child(window_layer, text_layer_get_layer(message_text));

  }
}

void hide_check_app_message() {
  if (message_text != NULL) {
    Layer *message_text_layer = text_layer_get_layer(message_text);
    layer_remove_from_parent(message_text_layer);
    text_layer_destroy(message_text);
    message_text = NULL;
  }
}

static void send_checklist_select(uint8_t list_id) {

  DictionaryIterator *dict;
  app_message_outbox_begin(&dict);
  dict_write_uint8(dict, CMD_CHECKLIST_SELECT, list_id);

  app_message_outbox_send();
}

// A callback is used to specify the amount of sections of menu items
// With this, you can dynamically add and remove sections
static uint16_t checklists_menu_get_num_sections_callback(MenuLayer *menu_layer, void *data) {
  return NUM_MENU_SECTIONS;
}

// Each section has a number of items;  we use a callback to specify this
// You can also dynamically add and remove items using this
static uint16_t checklists_menu_get_num_rows_callback(MenuLayer *menu_layer, uint16_t section_index, void *data) {
	if (checklists == NULL) {
		return 0;
	} else {
  		return checklists->count;
	}
}

// A callback is used to specify the height of the section header
static int16_t checklists_menu_get_header_height_callback(MenuLayer *menu_layer, uint16_t section_index, void *data) {
  // This is a define provided in pebble_os.h that you may use for the default height
  return MENU_CELL_BASIC_HEADER_HEIGHT;
}

// A callback is used to specify the height of the section header
static int16_t checklists_menu_get_cell_height_callback(MenuLayer *menu_layer, MenuIndex *cell_index, void *callback_context) {
  // This is a define provided in pebble_os.h that you may use for the default height
  return 24;
}

// Here we draw what each header is
static void checklists_menu_draw_header_callback(GContext* ctx, const Layer *cell_layer, uint16_t section_index, void *data) {
  menu_cell_basic_header_draw(ctx, cell_layer, checklists->name);
}

// This is the menu item draw callback where you specify what each item should look like
static void checklists_menu_draw_row_callback(GContext* ctx, const Layer *cell_layer, MenuIndex *cell_index, void *data) {
  if (cell_index->row < checklists->count) {
    ListItem *item = checklists->items[cell_index->row];
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
void checklists_menu_select_callback(MenuLayer *menu_layer, MenuIndex *cell_index, void *data) {
  DLOG("%s", __FUNCTION__);
  if (checklists->count == 0) {
    return;
  }
  ListItem *item = checklists->items[cell_index->row];
  int selected_list_id = item->item_id;
  send_checklist_select(selected_list_id);
}

static void discard_checklists() {
    if (checklists != NULL) {
    	list_destroy(checklists);
    	checklists = NULL;
	}
}

static void checklists_window_load(Window *window) {
  checklists = NULL;
  Layer *window_layer = window_get_root_layer(window);
  GRect bounds = layer_get_frame(window_layer);
  bounds.origin = GPointZero;

  // Create the menu layer
  checklists_menu = menu_layer_create(bounds);
  
  // Set all the callbacks for the menu layer
  menu_layer_set_callbacks(checklists_menu, NULL, (MenuLayerCallbacks){
    .get_num_sections = checklists_menu_get_num_sections_callback,
    .get_num_rows = checklists_menu_get_num_rows_callback,
    .get_header_height = checklists_menu_get_header_height_callback,
    .get_cell_height = checklists_menu_get_cell_height_callback,
    .draw_header = checklists_menu_draw_header_callback,
    .draw_row = checklists_menu_draw_row_callback,
    .select_click = checklists_menu_select_callback,
  });

  // Add it to the window for display
  layer_add_child(window_layer, menu_layer_get_layer(checklists_menu));
  menu_layer_reload_data(checklists_menu);

}

static void checklists_window_unload(Window *window) {
    discard_checklists();
  	menu_layer_destroy(checklists_menu);
}

Window *create_checklists_window() {
	Window *window = window_create();
	window_set_window_handlers(window, (WindowHandlers) {
    	.load = checklists_window_load,
    	.unload = checklists_window_unload,
  	});
	return window;
}