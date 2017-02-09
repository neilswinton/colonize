{{ sls | replace('.','_') }}_nop:
  test.succeed_without_changes
