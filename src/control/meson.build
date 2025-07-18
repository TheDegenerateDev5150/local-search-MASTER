sources = [
    'tracker-main.c',
    'tracker-miner-files-index.c',
    'tracker-miner-files-peer-listener.c',
]

tracker_index_deps = [
     tracker_miners_common_dep,
]

dbus_index_files_interface = files('org.freedesktop.Tracker3.Miner.Files.Index.xml')
dbus_index_proxy_interface = files('org.freedesktop.Tracker3.Miner.Files.Proxy.xml')

built_sources = []
built_sources += gnome.gdbus_codegen('tracker-dbus-files-index',
    dbus_index_files_interface,
    interface_prefix: 'org.freedesktop.Tracker3',
    namespace: 'TrackerDBus',
)

built_sources += gnome.gdbus_codegen('tracker-dbus-files-proxy',
    dbus_index_proxy_interface,
    interface_prefix: 'org.freedesktop.Tracker3',
    namespace: 'TrackerDBus',
)

install_data(dbus_index_files_interface,
    install_dir: join_paths(get_option('prefix'), get_option('datadir'), 'dbus-1', 'interfaces')
)

executable('localsearch-control-@0@'.format(tracker_api_major),
    sources + built_sources,
    dependencies: tracker_index_deps,
    c_args: tracker_c_args,
    install: true,
    install_dir: get_option('libexecdir'),
)

# This file allows starting the service with D-Bus autoactivation.
tmp_conf = configuration_data()
tmp_conf.merge_from(conf)
tmp_conf.set('dbusname', 'LocalSearch3.Control')
tmp_conf.set ('DOMAIN_PREFIX', get_option('domain_prefix'))
if get_option('domain_prefix') == 'org.freedesktop'
  tmp_conf.set ('SYSTEMD_SERVICE', 'SystemdService=localsearch-control-3.service')
else
  tmp_conf.set ('SYSTEMD_SERVICE', '')
endif
dbus_service_file = configure_file(
    input: 'org.freedesktop.Tracker3.Miner.Files.Control.service.in',
    output: get_option('domain_prefix') + '.LocalSearch3.Control.service',
    configuration: tmp_conf,
    install: true,
    install_dir: dbus_services_dir,
)

legacy_conf = configuration_data()
legacy_conf.merge_from(conf)
legacy_conf.set('dbusname', 'Tracker3.Miner.Files.Control')
legacy_conf.set ('DOMAIN_PREFIX', get_option('domain_prefix'))
if get_option('domain_prefix') == 'org.freedesktop'
  legacy_conf.set ('SYSTEMD_SERVICE', 'SystemdService=localsearch-control-3.service')
else
  legacy_conf.set ('SYSTEMD_SERVICE', '')
endif
dbus_service_file = configure_file(
    input: 'org.freedesktop.Tracker3.Miner.Files.Control.service.in',
    output: get_option('domain_prefix') + '.Tracker3.Miner.Files.Control.service',
    configuration: legacy_conf,
    install: true,
    install_dir: dbus_services_dir,
)

if get_option('systemd_user_services')
  # This file allows starting the service as a systemd user service.
  configure_file(
      input: 'tracker-control.service.in',
      output: 'localsearch-control-@0@.service'.format(tracker_api_major),
      configuration: conf,
      install: true,
      install_dir: systemd_user_services_dir)
endif
