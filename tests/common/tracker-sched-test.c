/*
 * Copyright (C) 2011, Nokia <ivan.frade@nokia.com>
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
#include "config-miners.h"

#include <glib.h>
#include <glib-object.h>
#include <tracker-common.h>

#ifdef __linux__
#include <linux/sched.h>
#endif


#include <sched.h>
#include <errno.h>


static gboolean
scheduler_is (gint scheduler)
{
#ifdef __linux__
        int policy;
        struct sched_param param;

        if (pthread_getschedparam (pthread_self (), &policy, &param) != 0) {
                g_assert_not_reached ();
        }
        return (policy == scheduler);
#else
        return TRUE;
#endif
}

static void
test_sched_set_and_get (void)
{
        g_assert_true (tracker_sched_idle ());
#ifdef __linux__
        g_assert_true (scheduler_is (SCHED_IDLE));
#endif
}


gint
main (gint argc, gchar **argv)
{
        g_test_init (&argc, &argv, NULL);

        g_test_add_func ("/libtracker-common/sched/set_and_get",
                         test_sched_set_and_get);

        return g_test_run ();
}
