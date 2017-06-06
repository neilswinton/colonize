users:
  juser:
    fullname: Joe User
    email: juser@userco.com
    sudoer: True
    bash_profile:
      environment:
        - EDITOR:  emacsclient
      includes:
        - /home/juser/git/home/.bash_profile
    ssh:
      private_keys:
        id_ecdsa: |
          -----BEGIN EC PRIVATE KEY-----
          MHcCAQEEINi3Qkindlem93ncW1dRaToujWK7yIhk4LVvEgakHX+AoAoGCCqGSM49
          kdodlmxDQgAE38LUeuMNcdWfkkdnWq70TMvMTHQY5lhgcKQemddr9r7I5qJjAnj8
          unwmQgxyONvbd/ldlfRTE7fc/I+0DWYbCg==
          -----END EC PRIVATE KEY-----
      public_keys:
        id_ecdsa.pub: "ecdsa-sha2-nistp256 AAAAEkd8ZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBN/C1HrjDXHVviUEUlqu9EzLzEx0GOZYYHCkHpnXa/a+yOaiYwJ4/Lp8JkIMcjjb23f7JcH0UxO33PyPtA1mGwo= juser@DESKTOP-ULD1IQU"
    git:
      config:
        - user.email: juser@userco.com
        - user.username: "Joe User"
        - alias.prune: "fetch --prune"
        - alias.undo: "fetch --soft HEAD^"
        - merge.ff: only
        - push.default: simple
        - transfer.fsckobjects: true
      repos:
        home:
          - name: git@github.com:juser/home.git
          - user: juser
          - target: /home/juser/git/home
          - rev: master
          - branch: master

