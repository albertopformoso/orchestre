/* Loaded only by waybar-power-menu through GTK_MODULES. */
#include <gtk/gtk.h>
#include <gmodule.h>

static gboolean focus_on_pointer(GtkWidget *widget, GdkEvent *event, gpointer data)
{
    (void)event;
    (void)data;
    if (!gtk_widget_has_focus(widget))
        gtk_widget_grab_focus(widget);
    return FALSE;
}

static gboolean watch_button(GSignalInvocationHint *hint, guint count,
                             const GValue *values, gpointer data)
{
    (void)hint;
    (void)count;
    (void)data;
    GtkWidget *widget = g_value_get_object(&values[0]);
    if (GTK_IS_BUTTON(widget) &&
        !g_object_get_data(G_OBJECT(widget), "orchestre-pointer-focus")) {
        g_object_set_data(G_OBJECT(widget), "orchestre-pointer-focus", GINT_TO_POINTER(1));
        gtk_widget_add_events(widget, GDK_ENTER_NOTIFY_MASK | GDK_POINTER_MOTION_MASK);
        g_signal_connect(widget, "enter-notify-event", G_CALLBACK(focus_on_pointer), NULL);
        g_signal_connect(widget, "motion-notify-event", G_CALLBACK(focus_on_pointer), NULL);
    }
    return TRUE;
}

G_MODULE_EXPORT void gtk_module_init(gint *argc, gchar ***argv)
{
    (void)argc;
    (void)argv;
    if (g_strcmp0(g_get_prgname(), "wlogout") != 0)
        return;
    gpointer widget_class = g_type_class_ref(GTK_TYPE_WIDGET);
    g_signal_add_emission_hook(g_signal_lookup("realize", GTK_TYPE_WIDGET),
                              0, watch_button, NULL, NULL);
    g_type_class_unref(widget_class);
}
