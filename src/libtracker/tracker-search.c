/* Tracker Search
 * Copyright (C) 2005, Mr Jamie McCracken (jamiemcc@gnome.org)	
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA. 
 */

#include <locale.h>
#include <glib.h>

#include "../libtracker/tracker.h" 

static gint limit = 0;
static gchar **terms = NULL;
static gchar *service = NULL;
static gboolean detailed;

static GOptionEntry entries[] = {
	{"limit", 'l', 0, G_OPTION_ARG_INT, &limit, "limit the number of results showed", "limit"},
	{"service", 's', 0, G_OPTION_ARG_STRING, &service, "search from a specific service", "service"},
	{"detailed", 'd', 0, G_OPTION_ARG_NONE, &detailed, "Show more detailed results with service and mime type as well", NULL},
	{G_OPTION_REMAINING, 0, 0, G_OPTION_ARG_STRING_ARRAY, &terms, "search terms", NULL},
	{NULL}
};


static void
get_meta_table_data (gpointer value)
		    
{
	char **meta, **meta_p;

	meta = (char **)value;

	int i = 0;
	for (meta_p = meta; *meta_p; meta_p++) {

		char *str;

		str = g_filename_from_utf8 (*meta_p, -1, NULL, NULL, NULL);

		if (i == 0) {
			g_print ("%s : ", str);

		} else {
			g_print ("%s, ", *meta_p);
		}
		i++;
	}
	g_print ("\n");
}

int
main (int argc, char **argv) 
{
	GOptionContext *context = NULL;
	TrackerClient *client = NULL;
	GError *error = NULL;
	ServiceType type;
	gchar *search;
	gchar **result;
	char **p_strarray;
	GPtrArray *out_array = NULL;

	setlocale (LC_ALL, "");

	context = g_option_context_new ("search terms ... - search files for certain terms (ANDed)");
	g_option_context_add_main_entries (context, entries, NULL);
	g_option_context_parse (context, &argc, &argv, &error);

	if (error) {
		g_printerr ("invalid arguments: %s\n", error->message);
		return 1;
	}

	if (!terms) {
		g_printerr ("missing search terms, try --help for help\n");
		return 1;
	}

	if (limit <= 0)
		limit = 512;

	client = tracker_connect (FALSE);

	if (!client) {
		g_printerr ("could not connect to Tracker\n");
		return 1;
	}

	if (!service) {
		type = SERVICE_FILES;
	} else if (g_ascii_strcasecmp (service, "Documents") == 0) {
		type = SERVICE_DOCUMENTS;
	} else if (g_ascii_strcasecmp (service, "Music") == 0) {
		type = SERVICE_MUSIC;
	} else if (g_ascii_strcasecmp (service, "Images") == 0) {
		type = SERVICE_IMAGES;
	} else if (g_ascii_strcasecmp (service, "Videos") == 0) {
		type = SERVICE_VIDEOS;
	} else if (g_ascii_strcasecmp (service, "Text") == 0) {
		type = SERVICE_TEXT_FILES;
	} else if (g_ascii_strcasecmp (service, "Development") == 0) {
		type = SERVICE_DEVELOPMENT_FILES;
	} else {
		g_printerr ("service not recognized, searching in Other Files...\n");
		type = SERVICE_OTHER_FILES;
	}

	search = g_strjoinv (" ", terms);

	if (!detailed) {
		result = tracker_search_text (client, -1, type, search, 0, limit, &error);
	} else  {
		out_array = tracker_search_text_detailed (client, -1, type, search, 0, limit, &error);
	}
	
	g_free (search);


	if (error) {
		g_printerr ("tracker raised error: %s\n", error->message);
		g_error_free (error);
		return 1;
	}

	if (!result) {
		g_printerr ("no results found\n");
		return 0;
	}

	if (detailed) {
		if (out_array) {
			g_ptr_array_foreach (out_array, (GFunc)get_meta_table_data, NULL);
			g_ptr_array_free (out_array, TRUE);
		}
		tracker_disconnect (client);
		return 0;
	} 


	
	for (p_strarray = result; *p_strarray; p_strarray++) {
		char *s = g_locale_from_utf8 (*p_strarray, -1, NULL, NULL, NULL);

		if (!s)
			continue;

		g_print ("%s\n", s);
		g_free (s);
	}

	g_strfreev (result);

	tracker_disconnect (client);
	return 0;

}
