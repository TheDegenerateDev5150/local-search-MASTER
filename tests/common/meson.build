libtracker_common_tests = [
    'dbus',
    'extract-info',
    'file-utils',
    'module-manager',
    'sched',
    'type-utils',
    'utils',
]

libtracker_miners_common_test_deps = [
    tracker_miners_common_dep, tracker_testcommon_dep
]

foreach base_name: libtracker_common_tests
    source = 'tracker-@0@-test.c'.format(base_name)
    binary_name = 'tracker-@0@-test'.format(base_name)

    binary = executable(binary_name, source,
      dependencies: [libtracker_miners_common_test_deps, gmodule],
      c_args: test_c_args)

    test(base_name, binary,
      protocol: test_protocol,
      suite: 'miners-common')
endforeach
