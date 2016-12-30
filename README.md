# retro

A webapp for running (remote) retrospectives.

## Install

```sh
$ go get hawx.me/code/retro
$ cd $GOPATH/src/hawx.me/code/retro
$ cd app
$ npm install
$ npm run build
$ GH_CLIENT_ID='abc' GH_CLIENT_SECRET='xyz' ORGANISATION='myorg' retro --assets dist
...
```

This will run the app `localhost:8080` by default (this can be changed by
passing `--port` or using `--socket`). Only GitHub users who are part of the
specified organisation will be able to Sign-in and join the retro.
