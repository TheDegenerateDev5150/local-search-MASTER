po_dir = join_paths(meson.project_source_root(), 'po')

tracker_uninstalled_cli_dir = meson.current_build_dir()

sources = files(
    'tracker-cli-utils.c',
    'tracker-daemon.c',
    'tracker-extract.c',
    'tracker-index.c',
    'tracker-info.c',
    'tracker-miner-manager.c',
    'tracker-process.c',
    'tracker-reset.c',
    'tracker-search.c',
    'tracker-status.c',
    'tracker-tag.c',
    'main.c'
)

python_commands = [
    { 'name': 'test-sandbox', 'source': 'tracker-sandbox.in' },
]

main_command_name = 'localsearch'

executable(main_command_name,
    sources,
    c_args: tracker_c_args + [
        '-DMAIN_COMMAND_NAME=@0@'.format(main_command_name),
        '-DLIBEXECDIR="@0@"'.format(join_paths(get_option('prefix'), get_option('libexecdir'))),
        '-DPYTHON_UTILS_DIR="@0@"'.format(testutils_dir / 'trackertestutils'),
        '-DBUILDROOT="@0@"'.format(build_root),
        '-DMANDIR="@0@"'.format(join_paths(get_option('prefix'), get_option('datadir'), 'man')),
        '-DBINDIR="@0@"'.format(join_paths(get_option('prefix'), get_option('bindir'))),
    ],
    install: true,
    install_dir: get_option('bindir'),
    dependencies: [tracker_sparql, tracker_miners_common_dep, gstreamer],
    include_directories: [commoninc, configinc, srcinc],
)

script_conf = configuration_data()
script_conf.set('typelibdir', typelib_dir)
script_conf.set('prefix', get_option('prefix'))
script_conf.set('testutils_dir', testutils_dir)

foreach c: python_commands
    command_name = 'localsearch@0@-@1@'.format(tracker_api_major, c['name'])

    configure_file(
        input: c['source'],
        output: command_name,
        configuration: script_conf,
        install_dir: testutils_dir / 'trackertestutils',
    )
endforeach

devenv = environment()
devenv.set('LOCALSEARCH_CLI_PATH', meson.current_build_dir())
meson.add_devenv(devenv)
