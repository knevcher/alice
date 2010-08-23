#! /bin/sh

### BEGIN INIT INFO
# Provides:          alice
# Required-Start:    $all
# Required-Stop:     $all
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: starts the alice rabbitmq monitor
# Description:       starts alice using start-stop-daemon
### END INIT INFO


PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
DAEMON=/usr/bin/erl
NAME=alice
DESC=alice
ALICE_DIR=/usr/lib/erlang/lib/alice

test -x $DAEMON || exit 0

[ -f /etc/default/alice ] && . /etc/default/alice

PIDFILE=/var/run/$NAME.pid;
DAEMON_OPTS="-pa $ALICE_DIR/ebin -pa $ALICE_DIR/deps/*/ebin -s reloader -boot alice -noinput -noshell -sname ${NODE_NAME} -setcookie ${COOKIE}";
DODTIME=1                   # Time to wait for the server to die, in seconds
                            # If this value is set too low you might not
                            # let some servers to die gracefully and
                            # 'restart' will not work

set -e

. /lib/lsb/init-functions

case "$1" in
  start)
        echo -n "Starting $DESC: "

        cd $ALICE_DIR

	if [ ! -f ebin/rest_app.boot ]; then
	    make boot
	fi

        start-stop-daemon --start --quiet --make-pidfile --background \
	    --pidfile $PIDFILE --exec $DAEMON -- $DAEMON_OPTS || true

        echo -n "$NAME."
        ;;
  stop)
        echo -n "Stopping $DESC: "

        start-stop-daemon --stop --quiet --pidfile $PIDFILE || true

        echo -n "$NAME."

        ;;
  restart|force-reload)

        echo -n "Restarting $DESC: "

	start-stop-daemon --stop --quiet --pidfile $PIDFILE || true

        [ -n "$DODTIME" ] && sleep $DODTIME

	start-stop-daemon --start --quiet --make-pidfile --background \
	    --pidfile $PIDFILE --exec $DAEMON -- $DAEMON_OPTS || true

        ;;
  status)
	status_of_proc -p /var/run/$NAME.pid "$DAEMON" $NAME && exit 0 || exit $?
	;;
  *)
    N=/etc/init.d/$NAME
    echo "Usage: $N {start|stop|restart|status}" >&2
    exit 1
    ;;
esac

exit 0
