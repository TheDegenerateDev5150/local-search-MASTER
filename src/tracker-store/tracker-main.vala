/*
 * Copyright (C) 2006, Jamie McCracken <jamiemcc@gnome.org>
 * Copyright (C) 2008-2011, Nokia <ivan.frade@nokia.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA  02110-1301, USA.
 */

class Tracker.Main {
	[CCode (cname = "PACKAGE_VERSION")]
	extern const string PACKAGE_VERSION;

	[CCode (cname = "SHAREDIR")]
	extern const string SHAREDIR;

	const string LICENSE = "This program is free software and comes without any warranty.
It is licensed under version 2 or later of the General Public
License which can be viewed at:
  http://www.gnu.org/licenses/gpl.txt
";

	const int SELECT_CACHE_SIZE = 100;
	const int UPDATE_CACHE_SIZE = 100;

	static MainLoop main_loop;
	static string log_filename;

	static bool shutdown;

	/* Private command line parameters */
	static bool version;
	static int verbosity;
	static bool force_reindex;
	static bool readonly_mode;
	static string domain_ontology;
	static string cache_location;
	static string data_location;
	static string ontology_location;
	static string dbus_path;
	static string domain;
	static string ontology_name;

	const OptionEntry entries[] = {
		/* Daemon options */
		{ "version", 'V', 0, OptionArg.NONE, ref version, N_("Displays version information"), null },
		{ "verbosity", 'v', 0, OptionArg.INT, ref verbosity, N_("Logging, 0 = errors only, 1 = minimal, 2 = detailed and 3 = debug (default = 0)"), null },

		/* Indexer options */
		{ "force-reindex", 'r', 0, OptionArg.NONE, ref force_reindex, N_("Force a re-index of all content"), null },
		{ "readonly-mode", 'n', 0, OptionArg.NONE, ref readonly_mode, N_("Only allow read based actions on the database"), null },
		{ "domain-ontology", 'd', 0, OptionArg.STRING, ref domain_ontology, N_("Load a specified domain ontology"), null },
		{ "domain", 'a', 0, OptionArg.STRING, ref domain, N_("Override domain to be used"), null },
		{ "ontology-name", 'o', 0, OptionArg.STRING, ref ontology_name, N_("Override ontology name to be used"), null },
		{ "dbus-path", 'p', 0, OptionArg.STRING, ref dbus_path, N_("Override DBus path to be used"), null },
		{ "cache-location", 'c', 0, OptionArg.STRING, ref cache_location, N_("Override cache location to be used"), null },
		{ "data-location", 'm', 0, OptionArg.STRING, ref data_location, N_("Override data location to be used"), null },
		{ "ontology-location", 'n', 0, OptionArg.STRING, ref ontology_location, N_("Override ontology location to be used"), null },

		{ null }
	};

	static void sanity_check_option_values (Tracker.Config config) {
		message ("General options:");
		message ("  Verbosity  ............................  %d", config.verbosity);

		message ("Store options:");
		message ("  Readonly mode  ........................  %s", readonly_mode ? "yes" : "no");
		message ("  GraphUpdated Delay ....................  %d", config.graphupdated_delay);

		if (domain_ontology != null)
			message ("  Domain ontology........................  %s", domain_ontology);

		if (domain != null)
			message ("  Domain.................................  %s", domain);
		if (ontology_name != null)
			message ("  Ontology name..........................  %s", ontology_name);

		if (cache_location != null)
			message ("  Cache location.........................  %s", cache_location);
		if (data_location != null)
			message ("  Data location..........................  %s", data_location);
		if (ontology_location != null)
			message ("  Ontology location......................  %s", ontology_location);
	}

	static void do_shutdown () {
		if (main_loop != null) {
			main_loop.quit ();
		}

		shutdown = true;
	}

	static bool shutdown_timeout_cb () {
		critical ("Could not exit in a timely fashion - terminating...");
		Process.exit (1);
	}

	static bool in_loop = false;

	static bool signal_handler (int signo) {
		/* Die if we get re-entrant signals handler calls */
		if (in_loop) {
			Process.exit (1);
		}

		switch (signo) {
		case Posix.SIGTERM:
		case Posix.SIGINT:
			in_loop = true;
			do_shutdown ();

			if (strsignal (signo) != null) {
				print ("\n");
				print ("Received signal:%d->'%s'", signo, strsignal (signo));
			}
			break;
		default:
			if (strsignal (signo) != null) {
				print ("\n");
				print ("Received signal:%d->'%s'", signo, strsignal (signo));
			}
			break;
		}

		return true;
	}

	static void initialize_signal_handler () {
		Unix.signal_add (Posix.SIGTERM, () => signal_handler (Posix.SIGTERM));
		Unix.signal_add (Posix.SIGINT, () => signal_handler (Posix.SIGINT));
	}

	static void initialize_priority () {
		/* Set disk IO priority and scheduling */
		Tracker.ioprio_init ();

		/* NOTE: We only set the nice() value when crawling, for all
		 * other times we don't have a nice() value. Check the
		 * tracker-status code to see where this is done.
		 */
	}

	[CCode (array_length = false, array_null_terminated = true)]
	static string[] get_writeback_predicates () {
		string[] predicates_to_signal = null;

		try {
			var cursor = Tracker.Data.query_sparql_cursor ("SELECT ?predicate WHERE { ?predicate tracker:writeback true }");

			while (cursor.next ()) {
				predicates_to_signal += cursor.get_string (0);
			}
		} catch (Error e) {
			critical ("Unable to retrieve tracker:writeback properties: %s", e.message);
		}

		return predicates_to_signal;
	}

	static void config_verbosity_changed_cb (Object object, ParamSpec? spec) {
		int verbosity = ((Tracker.Config) object).verbosity;

		message ("Log verbosity is set to %d, %s D-Bus client lookup",
		         verbosity,
		         verbosity > 0 ? "enabling" : "disabling");

		Tracker.DBusRequest.enable_client_lookup (verbosity > 0);
	}

	static int main (string[] args) {
		Intl.setlocale (LocaleCategory.ALL, "");

		Intl.bindtextdomain (GETTEXT_PACKAGE, LOCALEDIR);
		Intl.bind_textdomain_codeset (GETTEXT_PACKAGE, "UTF-8");
		Intl.textdomain (GETTEXT_PACKAGE);

		/* Set timezone info */
		tzset ();

		verbosity = -1;

		try {
			/* Translators: this messagge will apper immediately after the
			 * usage string - Usage: COMMAND <THIS_MESSAGE>
			 */
			var context = new OptionContext (_("— start the tracker daemon"));
			context.add_main_entries (entries, null);
			context.parse (ref args);
		} catch (Error e) {
			printerr ("Invalid arguments, %s\n", e.message);
			return 1;
		}

		if (version) {
			/* Print information */
			print ("\nTracker " + PACKAGE_VERSION + "\n\n" + LICENSE + "\n");
			return 0;
		}

		/* This makes sure we don't steal all the system's resources */
		initialize_priority ();

		/* Initialize major subsystems */
		var config = new Tracker.Config ();
		var db_config = new Tracker.DBConfig ();

		/* Daemon command line arguments */
		if (verbosity > -1) {
			config.verbosity = verbosity;
		}

		/* Initialize other subsystems */
		Tracker.Log.init (config.verbosity, out log_filename);
		if (log_filename != null) {
			message ("Using log file:'%s'", log_filename);
		}

		if (domain_ontology != null) {
			string keyfile_path = Path.build_filename (SHAREDIR,
			                                           "tracker",
			                                           "domain-ontologies",
			                                           domain_ontology+".rule");
			try {
				KeyFile keyfile = new KeyFile ( );
				keyfile.load_from_file (keyfile_path, GLib.KeyFileFlags.NONE);
				
				try {
					string? loaded_data_location = keyfile.get_string ("DomainOntology", "DataLocation");
					if (data_location == null)
						data_location = loaded_data_location;
				} catch (KeyFileError m) {}

				try {
					string? loaded_cache_location = keyfile.get_string ("DomainOntology", "CacheLocation");
					if (cache_location == null)
						cache_location = loaded_cache_location;
				} catch (KeyFileError m) {}

				try {
					string? loaded_ontology_location = keyfile.get_string ("DomainOntology", "OntologyLocation");
					if (ontology_location == null)
						ontology_location = loaded_ontology_location;
				} catch (KeyFileError m) {}

				try {
					string? loaded_dbus_path = keyfile.get_string ("DomainOntology", "DBusPath");
					if (dbus_path == null)
						dbus_path = loaded_dbus_path;
				} catch (KeyFileError m) {}

				try {
					string? loaded_domain = keyfile.get_string ("DomainOntology", "Domain");
					if (domain == null)
						domain = loaded_domain;
				} catch (KeyFileError m) {}

				try {
					string? loaded_ontology_name = keyfile.get_string ("DomainOntology", "OntologyName");
					if (ontology_name == null)
						ontology_name = loaded_ontology_name;
				} catch (KeyFileError m) {}

			} catch (KeyFileError ke) {
				critical("Loading " + keyfile_path + " " + ke.message);
			} catch (FileError fe) {
				critical("Loading " + keyfile_path + " " + fe.message);
			}
		}

		sanity_check_option_values (config);

		if (!Tracker.DBus.init (config)) {
			return 1;
		}

		/* Make sure we enable/disable the dbus client lookup */
		config_verbosity_changed_cb (config, null);
		ulong config_verbosity_id = config.notify["verbosity"].connect (config_verbosity_changed_cb);

		DBManagerFlags flags = DBManagerFlags.REMOVE_CACHE;

		if (force_reindex) {
			/* TODO port backup support
			   backup_user_metadata (config, language); */

			flags |= DBManagerFlags.FORCE_REINDEX;
		}

		var notifier = Tracker.DBus.register_notifier (domain, dbus_path, ontology_name);
		var busy_callback = notifier.get_callback ();

		Tracker.Store.init ();

		/* Make Tracker available for introspection */
		if (!Tracker.DBus.register_objects (domain, dbus_path, ontology_name)) {
			return 1;
		}

		if (!Tracker.DBus.register_names (domain, dbus_path, ontology_name)) {
			return 1;
		}

		int chunk_size_mb = db_config.journal_chunk_size;
		size_t chunk_size = (size_t) ((size_t) chunk_size_mb * (size_t) 1024 * (size_t) 1024);
		string rotate_to = db_config.journal_rotate_destination;

		if (rotate_to == "") {
			rotate_to = null;
		}

		bool do_rotating = (chunk_size_mb != -1);

		Tracker.DBJournal.set_rotating (do_rotating, chunk_size, rotate_to);

		int select_cache_size, update_cache_size;
		string cache_size_s;

		cache_size_s = Environment.get_variable ("TRACKER_STORE_SELECT_CACHE_SIZE");
		if (cache_size_s != null && cache_size_s != "") {
			select_cache_size = int.parse (cache_size_s);
		} else {
			select_cache_size = SELECT_CACHE_SIZE;
		}

		cache_size_s = Environment.get_variable ("TRACKER_STORE_UPDATE_CACHE_SIZE");
		if (cache_size_s != null && cache_size_s != "") {
			update_cache_size = int.parse (cache_size_s);
		} else {
			update_cache_size = UPDATE_CACHE_SIZE;
		}

		bool is_first_time_index;

		try {
			File final_cache_location = cache_location != null ?
				File.new_for_path (cache_location.replace ("%HOME%", Environment.get_home_dir()).replace("%SHAREDIR%", SHAREDIR)) :
				File.new_for_path (Path.build_filename (Environment.get_user_cache_dir (), "tracker"));
			File final_data_location = data_location != null ?
				File.new_for_path (data_location.replace ("%HOME%", Environment.get_home_dir()).replace("%SHAREDIR%", SHAREDIR)) :
				File.new_for_path (Path.build_filename (Environment.get_user_data_dir (), "tracker", "data"));
			File final_ontology_location = ontology_location != null ?
				File.new_for_path (ontology_location.replace ("%HOME%", Environment.get_home_dir()).replace("%SHAREDIR%", SHAREDIR)) :
				File.new_for_path (Path.build_filename (SHAREDIR, "tracker", "ontologies", "nepomuk"));

			var env_ontology = Environment.get_variable ("TRACKER_DB_ONTOLOGIES_DIR");
			if (env_ontology != null && env_ontology != "")
				final_ontology_location = File.new_for_path (env_ontology);

			Tracker.Data.Manager.init (flags,
			                           final_cache_location,
			                           final_data_location,
			                           final_ontology_location,
			                           out is_first_time_index,
			                           true,
			                           false,
			                           select_cache_size,
			                           update_cache_size,
			                           busy_callback,
			                           "Initializing");
		} catch (GLib.Error e) {
			critical ("Cannot initialize database: %s", e.message);
			return 1;
		}

		db_config = null;
		notifier = null;

		if (!shutdown) {
			Tracker.DBus.register_prepare_class_signal ();

			Tracker.Events.init ();
			Tracker.Writeback.init (get_writeback_predicates);
			Tracker.Store.resume ();

			message ("Waiting for D-Bus requests...");
		}

		/* Set our status as running, if this is FALSE, threads stop
		 * doing what they do and shutdown.
		 */
		if (!shutdown) {
			main_loop = new MainLoop ();

			initialize_signal_handler ();

			main_loop.run ();
		}

		/*
		 * Shutdown the daemon
		 */
		message ("Shutdown started");

		Tracker.Store.shutdown ();

		Timeout.add (5000, shutdown_timeout_cb, Priority.LOW);

		message ("Cleaning up");

		/* Shutdown major subsystems */
		Tracker.Writeback.shutdown ();
		Tracker.Events.shutdown ();

		Tracker.DBus.shutdown (domain, dbus_path, ontology_name);
		Tracker.Data.Manager.shutdown ();
		Tracker.Log.shutdown ();

		config.disconnect (config_verbosity_id);
		config = null;

		/* This will free rotate_to up in the journal code */
		Tracker.DBJournal.set_rotating ((chunk_size_mb != -1), chunk_size, null);

		print ("\nOK\n\n");

		log_filename = null;

		main_loop = null;

		return 0;
	}

	[CCode (cname = "GETTEXT_PACKAGE")]
	extern const string GETTEXT_PACKAGE;
	[CCode (cname = "LOCALEDIR")]
	extern const string LOCALEDIR;

	[CCode (cname = "tzset", cheader_filename = "time.h")]
	extern static void tzset ();
}
