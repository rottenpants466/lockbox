/*
* Copyright (c) 2019 skärva LLC. <https://skarva.tech>
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*/

namespace Lockbox {
    public class MainWindow : Gtk.ApplicationWindow {
        public weak Lockbox.Application app { get; construct; }

        private Gtk.Stack layout_stack;
        private Widgets.CollectionList collection_list;
        private Widgets.WelcomeScreen welcome;

        private Services.CollectionManager collection_manager;
        private Gtk.Clipboard clipboard;
        private uint clipboard_timer_id = 0;

        public SimpleActionGroup actions { get; construct; }

        public const string ACTION_PREFIX = "lockbox.";
        public const string ACTION_ADD_LOGIN = "action_add_login";
        public const string ACTION_ADD_NOTE = "action_add_note";
        public const string ACTION_PREFERENCES = "action_preferences";
        public const string ACTION_UNDO = "action_undo";
        public const string ACTION_QUIT = "action_quit";

        public static Gee.MultiMap<string, string> action_accelerators = new Gee.HashMultiMap<string, string> ();

        public const ActionEntry[] action_entries = {
            { ACTION_ADD_LOGIN, action_add_login },
            { ACTION_ADD_NOTE, action_add_note },
            { ACTION_PREFERENCES, action_preferences },
            { ACTION_UNDO, action_undo },
            { ACTION_QUIT, action_quit }
        };

        public MainWindow (Lockbox.Application app) {
            Object (
                application: app,
                app: app,
                icon_name: Constants.PROJECT_NAME
            );
        }

        static construct {
            action_accelerators.set (ACTION_ADD_LOGIN, "<Control>a");
            action_accelerators.set (ACTION_ADD_NOTE, "<Control>n");
            action_accelerators.set (ACTION_UNDO, "<Control>z");
            action_accelerators.set (ACTION_QUIT, "<Control>q");
        }

        construct {
            /* Load up Secret Service and Collections */
            collection_manager = new Services.CollectionManager ();

            /* Set up actions and hotkeys */
            actions = new SimpleActionGroup ();
            actions.add_action_entries (action_entries, this);
            insert_action_group ("lockbox", actions);

            foreach (var action in action_accelerators.get_keys ()) {
                app.set_accels_for_action (ACTION_PREFIX + action, action_accelerators[action].to_array ());
            }

            /* Load State and Settings */
            var saved_state = Services.SavedState.get_default ();
            set_default_size (saved_state.window_width, saved_state.window_height);
            if (saved_state.window_x == -1 || saved_state.window_y == -1) {
                window_position = Gtk.WindowPosition.CENTER;
            } else {
                move (saved_state.window_x, saved_state.window_y);
            }

            if (saved_state.maximized) {
                this.maximize ();
            }

            Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = Services.Settings.get_default ().dark_theme;

            /* Init clipboard */
            clipboard = Gtk.Clipboard.get_for_display (get_display (), Gdk.SELECTION_CLIPBOARD);

            /* Init Layout */
            var headerbar = new Widgets.HeaderBar ();
            set_titlebar (headerbar);

            layout_stack = new Gtk.Stack ();
            add (layout_stack);

            welcome = new Widgets.WelcomeScreen ();
            welcome.show_preferences.connect (action_preferences);
            layout_stack.add_named (welcome, "welcome");

            var scroll_window = new Gtk.ScrolledWindow (null, null);

            collection_list = new Widgets.CollectionList ();
            scroll_window.add (collection_list);
            layout_stack.add_named (scroll_window, "collection");

            layout_stack.visible_child_name = "welcome";

            collection_manager.loaded.connect (() => {
                collection_list.populate (collection_manager.get_items (CollectionType.LOGIN));
                collection_list.populate (collection_manager.get_items (CollectionType.NOTE));
                layout_stack.visible_child_name = "collection";
            });

            show_all ();
        }

        protected override bool delete_event (Gdk.EventAny event) {
            // collection_list.clean ();
            collection_manager.close ();
            update_saved_state ();

            return false;
        }

        private void action_add_login () {
            var add_dialog = new Dialogs.AddLoginDialog (this);
            add_dialog.new_login.connect ((item) => {
                // Add login to collection_manager
                collection_list.add_login (item);
            });
            add_dialog.show_all ();

            add_dialog.present ();
        }

        private void action_add_note () {
            // Add note to collection_manager
            // Add note to collection_list
        }

        private void action_preferences () {
            var preferences_dialog = new Dialogs.PreferencesDialog (this);
            preferences_dialog.show_all ();

            preferences_dialog.present ();
        }

        private void action_undo () {
            // collection_list.undo ();
        }

        private void action_quit () {
            // collection_list.perform_removal ();
            collection_manager.close ();
            update_saved_state ();
            destroy ();
        }

        private void update_saved_state () {
            var saved_state = Services.SavedState.get_default ();
            int window_width;
            int window_height;
            int window_x;
            int window_y;
            get_size (out window_width, out window_height);
            get_position (out window_x, out window_y);
            saved_state.window_width = window_width;
            saved_state.window_height = window_height;
            saved_state.window_x = window_x;
            saved_state.window_y = window_y;
            saved_state.maximized = is_maximized;
        }

        private bool clear_clipboard_timed_out () {
            if (Services.Settings.get_default ().clear_clipboard) {
                clipboard_timer_id = 0;
                clipboard.clear ();
            }
            return true;
        }

        private void reset_clipboard_timer () {
            if (clipboard_timer_id > 0) {
                GLib.Source.remove (clipboard_timer_id);
                clipboard_timer_id = 0;
            }
            clipboard_timer_id = GLib.Timeout.add_seconds (Services.Settings.get_default ().clear_clipboard_timeout,
                                                             clear_clipboard_timed_out);
        }
    }
} // Lockbox
