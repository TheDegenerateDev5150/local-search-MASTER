/*
 * Copyright (C) 2017, Red Hat, Inc.
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
 * Authors: Carlos Garnacho <carlosg@gnome.org>
 */

#ifndef __TRACKER_DOMAIN_ONTOLOGY_H__
#define __TRACKER_DOMAIN_ONTOLOGY_H__

#include <glib-object.h>
#include <gio/gio.h>

typedef struct _TrackerDomainOntology TrackerDomainOntology;

#define TRACKER_TYPE_DOMAIN_ONTOLOGY (tracker_domain_ontology_get_type ())
GType tracker_domain_ontology_get_type (void) G_GNUC_CONST;

TrackerDomainOntology * tracker_domain_ontology_new      (const gchar   *name,
                                                          GCancellable  *cancellable,
                                                          GError       **error);
TrackerDomainOntology * tracker_domain_ontology_ref      (TrackerDomainOntology *domain_ontology);

void    tracker_domain_ontology_unref        (TrackerDomainOntology *domain_ontology);

GFile * tracker_domain_ontology_get_cache    (TrackerDomainOntology *domain_ontology);

gchar * tracker_domain_ontology_get_domain   (TrackerDomainOntology *domain_ontology,
                                              const gchar           *suffix);

gboolean tracker_domain_ontology_uses_miner  (TrackerDomainOntology *domain_ontology,
                                              const gchar           *suffix);

G_DEFINE_AUTOPTR_CLEANUP_FUNC (TrackerDomainOntology, tracker_domain_ontology_unref);

#endif /* __TRACKER_DOMAIN_ONTOLOGY_H__ */
