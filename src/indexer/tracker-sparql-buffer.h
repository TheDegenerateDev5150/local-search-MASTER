/*
 * Copyright (C) 2011, Nokia <ivan.frade@nokia.com>
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
 *
 * Author: Carlos Garnacho <carlos@lanedo.com>
 */

#ifndef __LIBTRACKER_MINER_SPARQL_BUFFER_H__
#define __LIBTRACKER_MINER_SPARQL_BUFFER_H__

#include <glib-object.h>
#include <gio/gio.h>
#include <tinysparql.h>

#include "tracker-task-pool.h"

G_BEGIN_DECLS

/* Task pool */
#define TRACKER_TYPE_SPARQL_BUFFER         (tracker_sparql_buffer_get_type())
#define TRACKER_SPARQL_BUFFER(o)           (G_TYPE_CHECK_INSTANCE_CAST ((o), TRACKER_TYPE_SPARQL_BUFFER, TrackerSparqlBuffer))
#define TRACKER_SPARQL_BUFFER_CLASS(c)     (G_TYPE_CHECK_CLASS_CAST ((c),    TRACKER_TYPE_SPARQL_BUFFER, TrackerSparqlBufferClass))
#define TRACKER_IS_SPARQL_BUFFER(o)        (G_TYPE_CHECK_INSTANCE_TYPE ((o), TRACKER_TYPE_SPARQL_BUFFER))
#define TRACKER_IS_SPARQL_BUFFER_CLASS(c)  (G_TYPE_CHECK_CLASS_TYPE ((c),    TRACKER_TYPE_SPARQL_BUFFER))
#define TRACKER_SPARQL_BUFFER_GET_CLASS(o) (G_TYPE_INSTANCE_GET_CLASS ((o),  TRACKER_TYPE_SPARQL_BUFFER, TrackerSparqlBufferClass))

typedef struct _TrackerSparqlBuffer TrackerSparqlBuffer;
typedef struct _TrackerSparqlBufferClass TrackerSparqlBufferClass;

struct _TrackerSparqlBuffer
{
	TrackerTaskPool parent_instance;
};

struct _TrackerSparqlBufferClass
{
	TrackerTaskPoolClass parent_class;
};

GType                tracker_sparql_buffer_get_type (void) G_GNUC_CONST;

TrackerSparqlBuffer *tracker_sparql_buffer_new   (TrackerSparqlConnection *connection,
                                                  guint                    limit);

gboolean             tracker_sparql_buffer_flush (TrackerSparqlBuffer *buffer,
                                                  const gchar         *reason,
                                                  GAsyncReadyCallback  cb,
                                                  gpointer             user_data);

GPtrArray *          tracker_sparql_buffer_flush_finish (TrackerSparqlBuffer  *buffer,
                                                         GAsyncResult         *res,
                                                         GError              **error);

gchar *              tracker_sparql_task_get_sparql          (TrackerTask *task);

void tracker_sparql_buffer_log_delete (TrackerSparqlBuffer *buffer,
                                       GFile               *file);

void tracker_sparql_buffer_log_delete_content (TrackerSparqlBuffer *buffer,
                                               GFile               *file);

void tracker_sparql_buffer_log_move (TrackerSparqlBuffer *buffer,
                                     GFile               *source,
                                     GFile               *dest,
                                     const gchar         *dest_data_source);

void tracker_sparql_buffer_log_move_content (TrackerSparqlBuffer *buffer,
                                             GFile               *source,
                                             GFile               *dest);

void tracker_sparql_buffer_log_clear_content (TrackerSparqlBuffer *buffer,
                                              GFile               *file);

void tracker_sparql_buffer_log_file (TrackerSparqlBuffer *buffer,
                                     GFile               *file,
                                     const gchar         *content_graph,
                                     TrackerResource     *file_resource,
                                     TrackerResource     *graph_resource);

void tracker_sparql_buffer_log_folder (TrackerSparqlBuffer *buffer,
                                       GFile               *file,
                                       gboolean             is_root,
                                       TrackerResource     *file_resource,
                                       TrackerResource     *folder_resource);

void tracker_sparql_buffer_log_attributes_update (TrackerSparqlBuffer *buffer,
                                                  GFile               *file,
                                                  const gchar         *content_graph,
                                                  TrackerResource     *file_resource,
                                                  TrackerResource     *graph_resource);

G_END_DECLS

#endif /* __LIBTRACKER_MINER_SPARQL_BUFFER_H__ */
