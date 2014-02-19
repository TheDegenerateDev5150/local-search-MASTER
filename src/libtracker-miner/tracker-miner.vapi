/*
 * Copyright (C) 2010, Adrien Bustany (abustany@gnome.org)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA  02110-1301, USA.
 */

[CCode (cprefix = "Tracker", lower_case_cprefix = "tracker_")]
namespace Tracker {
	[CCode (cheader_filename = "libtracker-miner/tracker-miner.h")]
	public class Miner : GLib.Object, GLib.Initable {
		[CCode (has_construct_function = false)]
		public Miner ();
		[NoAccessorMethod]
		public string name { get; construct; }
		[NoAccessorMethod]
		public string status { get; set; }
		[NoAccessorMethod]
		public double progress { get; set; }
		public static GLib.Quark error_quark ();
		public void ignore_next_update (string[] urls);
		public bool is_started ();
		public int pause (string reason) throws GLib.Error;
		public virtual void paused ();
		public bool resume (int cookie) throws GLib.Error;
		public virtual void resumed ();
		public void start ();
		public virtual void started ();
		public void stop ();
		public virtual void stopped ();
		public signal void error (GLib.Error e);
		public unowned Tracker.Sparql.Connection? get_connection ();
		public unowned GLib.DBusConnection? get_dbus_connection ();
		public unowned string get_dbus_full_name ();
		public unowned string get_dbus_full_path ();
	}
	[CCode (ref_function = "tracker_miner_fs_ref", unref_function = "tracker_miner_fs_unref", cheader_filename = "libtracker-miner/tracker-miner.h")]
	public class MinerFS : Tracker.Miner, GLib.Initable {
		public virtual bool check_directory (GLib.File directory);
		public virtual bool check_directory_contents (GLib.File directory, GLib.List<GLib.File> children);
		public virtual bool check_file (GLib.File file);
		public void directory_add (GLib.File file, bool recurse);
		public bool directory_remove (GLib.File file);
		public void file_add (GLib.File file);
		public void file_notify (GLib.File file, GLib.Error error);
		public unowned string get_parent_urn (GLib.File file);
		public double get_throttle ();
		public unowned string get_urn (GLib.File file);
		public virtual bool monitor_directory (GLib.File directory);
		public void set_throttle (double throttle);
		public signal void finished (double elapsed, uint directories_found, uint directories_ignored, uint files_found, uint files_ignored);
	}
	[CCode (cheader_filename = "libtracker-miner/tracker-miner.h")]
	public class MinerWeb : Tracker.Miner, GLib.Initable {
		[CCode (has_construct_function = false)]
		public MinerWeb ();
		[NoAccessorMethod]
		public bool associated { get; set; }
		public virtual void associate (GLib.HashTable association_data) throws Tracker.MinerWebError;
		public virtual void authenticate () throws Tracker.MinerWebError;
		public virtual void dissociate () throws Tracker.MinerWebError;
		public static GLib.Quark error_quark ();
		public virtual GLib.HashTable get_association_data () throws Tracker.MinerWebError;
	}
	[CCode (cheader_filename = "libtracker-miner/tracker-miner.h")]
	public interface PasswordProvider : GLib.Object {
		public void forget_password (string service) throws GLib.Error;
		public static unowned Tracker.PasswordProvider @get ();
		public string get_name ();
		public string get_password (string service, out string username) throws GLib.Error;
		public void store_password (string service, string description, string username, string password) throws GLib.Error;
	}
	[CCode (cheader_filename = "libtracker-miner/tracker-miner.h")]
	public interface NetworkProvider : GLib.Object {
		public string get_name ();
		public NetworkProviderStatus get_status ();
		public signal void status_changed (NetworkProviderStatus status);
		public static unowned Tracker.NetworkProvider @get ();
	}
	[CCode (cprefix = "TRACKER_NETWORK_PROVIDER_", cheader_filename = "libtracker-miner/tracker-miner.h")]
	public enum NetworkProviderStatus {
		DISCONNECTED,
		UNKNOWN,
		GPRS,
		EDGE,
		@3G,
		LAN
	}
	[CCode (cprefix = "TRACKER_MINER_WEB_ERROR_", cheader_filename = "libtracker-miner/tracker-miner.h")]
	public errordomain MinerWebError {
		WRONG_CREDENTIALS,
		TOKEN_EXPIRED,
		NO_CREDENTIALS,
		KEYRING,
		SERVICE,
		TRACKER,
	}
	[CCode (cprefix = "TRACKER_PASSWORD_PROVIDER_ERROR_", cheader_filename = "libtracker-miner/tracker-miner.h")]
	public errordomain PasswordProviderError {
		SERVICE,
		NOTFOUND,
	}
	[CCode (cheader_filename = "libtracker-miner/tracker-miner.h")]
	public const string MINER_WEB_DBUS_INTERFACE;
}
