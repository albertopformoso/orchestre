/* Waybar CFFI ABI v2: a fixed-width, hover-scrolling media title.
 * Receives the existing media service's JSON stream over its local socket. */
#include <gtk/gtk.h>
#include <json-glib/json-glib.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>
#include <string.h>

typedef struct wbcffi_module wbcffi_module;
typedef struct {
    wbcffi_module *obj;
    const char *waybar_version;
    GtkContainer *(*get_root_widget)(wbcffi_module *);
    void (*queue_update)(wbcffi_module *);
} InitInfo;
typedef struct { const char *key; const char *value; } ConfigEntry;
const size_t wbcffi_version = 2;

typedef struct {
    GtkWidget *area;
    GIOChannel *channel;
    guint input, retry, animation;
    char *text;
    gboolean hover;
    double offset;
    gint64 last_tick, hold_until;
} Title;

static void reset_scroll(Title *t) {
    t->offset = 0;
    t->last_tick = g_get_monotonic_time();
    t->hold_until = t->last_tick + 700000;
    gtk_widget_queue_draw(t->area);
}

static gboolean draw(GtkWidget *widget, cairo_t *cr, gpointer data) {
    Title *t = data;
    int width, height;
    PangoLayout *layout = gtk_widget_create_pango_layout(widget, t->text);
    pango_layout_set_single_paragraph_mode(layout, TRUE);
    pango_layout_get_pixel_size(layout, &width, &height);
    int allocated = gtk_widget_get_allocated_width(widget);
    if (!t->hover) {
        pango_layout_set_width(layout, allocated * PANGO_SCALE);
        pango_layout_set_ellipsize(layout, PANGO_ELLIPSIZE_END);
    }
    cairo_save(cr);
    cairo_rectangle(cr, 0, 0, allocated, gtk_widget_get_allocated_height(widget));
    cairo_clip(cr);
    gtk_render_layout(gtk_widget_get_style_context(widget), cr, -t->offset,
                      (gtk_widget_get_allocated_height(widget) - height) / 2.0, layout);
    cairo_restore(cr);
    g_object_unref(layout);
    return FALSE;
}

static gboolean animate(gpointer data) {
    Title *t = data;
    gint64 now = g_get_monotonic_time();
    double elapsed = MIN((now - t->last_tick) / 1000000.0, 0.1);
    t->last_tick = now;
    if (now < t->hold_until) return G_SOURCE_CONTINUE;
    PangoLayout *layout = gtk_widget_create_pango_layout(t->area, t->text);
    int width;
    pango_layout_get_pixel_size(layout, &width, NULL);
    g_object_unref(layout);
    int overflow = width - gtk_widget_get_allocated_width(t->area);
    if (overflow <= 0) return G_SOURCE_CONTINUE;
    if (t->offset >= overflow) {
        reset_scroll(t);
    } else {
        t->offset = MIN(t->offset + elapsed * 28, overflow);
        if (t->offset >= overflow) t->hold_until = now + 1200000;
        gtk_widget_queue_draw(t->area);
    }
    return G_SOURCE_CONTINUE;
}

static gboolean enter(GtkWidget *widget, GdkEventCrossing *event, gpointer data) {
    (void)widget; (void)event;
    Title *t = data;
    t->hover = TRUE;
    reset_scroll(t);
    if (!t->animation) t->animation = g_timeout_add(33, animate, t);
    return FALSE;
}

static gboolean leave(GtkWidget *widget, GdkEventCrossing *event, gpointer data) {
    (void)widget; (void)event;
    Title *t = data;
    t->hover = FALSE;
    if (t->animation) g_source_remove(t->animation);
    t->animation = 0;
    reset_scroll(t);
    return FALSE;
}

static void set_text(Title *t, const char *text) {
    if (g_strcmp0(t->text, text) != 0) {
        g_free(t->text);
        t->text = g_strdup(text);
        reset_scroll(t);
    }
    gtk_widget_set_visible(t->area, *text != '\0');
}

static gboolean receive(GIOChannel *channel, GIOCondition condition, gpointer data) {
    Title *t = data;
    if (!(condition & (G_IO_HUP | G_IO_ERR))) {
        char *line = NULL;
        GIOStatus status;
        while ((status = g_io_channel_read_line(channel, &line, NULL, NULL, NULL)) == G_IO_STATUS_NORMAL) {
            JsonParser *parser = json_parser_new();
            if (json_parser_load_from_data(parser, line, -1, NULL)) {
                JsonNode *root = json_parser_get_root(parser);
                if (JSON_NODE_HOLDS_OBJECT(root)) {
                    JsonObject *object = json_node_get_object(root);
                    const char *markup = json_object_get_string_member_with_default(object, "text", "");
                    char *plain = NULL;
                    if (pango_parse_markup(markup, -1, 0, NULL, &plain, NULL, NULL)) {
                        set_text(t, plain);
                        g_free(plain);
                    }
                    const char *state = json_object_get_string_member_with_default(object, "class", "");
                    GtkStyleContext *style = gtk_widget_get_style_context(t->area);
                    if (strcmp(state, "paused") == 0) gtk_style_context_add_class(style, "paused");
                    else gtk_style_context_remove_class(style, "paused");
                }
            }
            g_object_unref(parser);
            g_free(line);
            line = NULL;
        }
        if (status == G_IO_STATUS_AGAIN) return G_SOURCE_CONTINUE;
    }
    t->input = 0;
    g_io_channel_unref(t->channel);
    t->channel = NULL;
    set_text(t, "");
    return G_SOURCE_REMOVE;
}

static gboolean connect_service(gpointer data) {
    Title *t = data;
    if (t->channel) return G_SOURCE_CONTINUE;
    struct sockaddr_un address = {.sun_family = AF_UNIX};
    g_snprintf(address.sun_path, sizeof(address.sun_path), "%s/waybar-media.sock", g_get_user_runtime_dir());
    int fd = socket(AF_UNIX, SOCK_STREAM | SOCK_CLOEXEC, 0);
    if (fd < 0) return G_SOURCE_CONTINUE;
    if (connect(fd, (struct sockaddr *)&address, sizeof(address)) < 0 ||
        send(fd, "watch title\n", 12, MSG_NOSIGNAL) != 12) {
        close(fd);
        return G_SOURCE_CONTINUE;
    }
    t->channel = g_io_channel_unix_new(fd);
    g_io_channel_set_close_on_unref(t->channel, TRUE);
    g_io_channel_set_flags(t->channel, G_IO_FLAG_NONBLOCK, NULL);
    t->input = g_io_add_watch(t->channel, G_IO_IN | G_IO_HUP | G_IO_ERR, receive, t);
    return G_SOURCE_CONTINUE;
}

void *wbcffi_init(const InitInfo *info, const ConfigEntry *entries, size_t count) {
    (void)entries; (void)count;
    Title *t = g_new0(Title, 1);
    t->text = g_strdup("");
    t->area = gtk_drawing_area_new();
    gtk_widget_set_name(t->area, "media-title");
    gtk_widget_set_size_request(t->area, 192, -1);
    gtk_widget_set_no_show_all(t->area, TRUE);
    gtk_widget_add_events(t->area, GDK_ENTER_NOTIFY_MASK | GDK_LEAVE_NOTIFY_MASK);
    g_signal_connect(t->area, "draw", G_CALLBACK(draw), t);
    g_signal_connect(t->area, "enter-notify-event", G_CALLBACK(enter), t);
    g_signal_connect(t->area, "leave-notify-event", G_CALLBACK(leave), t);
    gtk_container_add(info->get_root_widget(info->obj), t->area);
    t->retry = g_timeout_add_seconds(1, connect_service, t);
    connect_service(t);
    return t;
}

void wbcffi_deinit(void *instance) {
    Title *t = instance;
    if (!t) return;
    if (t->input) g_source_remove(t->input);
    if (t->retry) g_source_remove(t->retry);
    if (t->animation) g_source_remove(t->animation);
    if (t->channel) g_io_channel_unref(t->channel);
    g_signal_handlers_disconnect_by_data(t->area, t);
    g_free(t->text);
    g_free(t);
}
