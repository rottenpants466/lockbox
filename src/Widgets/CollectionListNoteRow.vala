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

namespace Lockbox.Widgets {
    public class CollectionListNoteRow : CollectionListRow {
        private Gtk.Box container;
        private Gtk.Label title;
        private Gtk.Button edit_item;
        private Gtk.Button delete_item;

        public signal void copy_username (Interfaces.Item item);
        public signal void copy_password (Interfaces.Item item);
        public signal void edit_entry(Interfaces.Item item);
        public signal void delete_entry (CollectionListRow row);

        public CollectionListNoteRow (Interfaces.Item item) {
            this.activatable = true;
            this.item = item;

            container = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            container.height_request = 50;

            title = new Gtk.Label (item.name);

            edit_item = new Gtk.Button.from_icon_name ("accessories-text-editor-symbolic", Gtk.IconSize.BUTTON);
            edit_item.relief = Gtk.ReliefStyle.NONE;
            delete_item = new Gtk.Button.from_icon_name ("edit-delete-symbolic", Gtk.IconSize.BUTTON);
            delete_item.relief = Gtk.ReliefStyle.NONE;

            container.pack_start (title);
            container.pack_start (edit_item, false, false ,5);
            container.pack_start (delete_item, false, false, 5);

            add (container);

            edit_item.clicked.connect (() => {
                edit_entry(item);
            });

            delete_item.clicked.connect ( () => {
                delete_entry (this);
            });
        }
    }
}
