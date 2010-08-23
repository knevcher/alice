#! /bin/sh

### BEGIN INIT INFO
# Provides:          hh-php-app
# Required-Start:    $all
# Required-Stop:     $all
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: starts the spawn-fcgi for hh-php-app component
# Description:       starts spawn-fcgi using start-stop-daemon
### END INIT INFO


PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
DAEMON=/usr/sbin/alice
NAME=alice
DESC=alice

test -x $DAEMON || exit 0

[ -f /etc/default/alice ] && . /etc/default/alice

PIDFILE=/var/run/$NAME.pid;
DAEMON_OPTS="-noinput -sname ${NODE_NAME} -setcookie ${COOKIE}";
DODTIME=1                   # Time to wait for the server to die, in seconds
                            # If this value is set too low you might not
                            # let some servers to die gracefully and
                            # 'restart' will not work

set -e

running_pid()
{
    # Check if a given process pid's cmdline matches a given name
    pid=$1
    name=$NAME

    [ -z "$pid" ] && return 1
    [ ! -d /proc/$pid ] &&  return 1
    cmd=`cat /proc/$pid/cmdline | tr "\000" "\n"|head -n 1 |cut -d : -f 1`
    # Is this the expected child?
    [ "$cmd" != "$name" ] &&  return 1
    return 0
}

running()
{
# Check if the process is running looking at /proc
# (works for all users)
    # No pidfile, probably no daemon present
    [ ! -f "$PIDFILE" ] && return 1
    # Obtain the pid and check it against the binary name
    pid=`cat $PIDFILE`

    running_pid $pid $DAEMON || return 1
    return 0
}

force_stop() {
# Forcefully kill the process
    [ ! -f "$PIDFILE" ] && return
    if running ; then
        kill -15 $pid
        # Is it really dead?
        [ -n "$DODTIME" ] && sleep "$DODTIME"s
        if running ; then
            kill -9 $pid
            [ -n "$DODTIME" ] && sleep "$DODTIME"s
            if running ; then
                echo "Cannot kill $LABEL (pid=$pid)!"
                exit 1
            fi
        fi
    fi
    rm -f $PIDFILE
    return 0
}

case "$1" in
  start)
        echo -n "Starting $DESC: "

        start-stop-daemon --start --quiet --pidfile $PIDFILE \
            --exec $DAEMON -- $DAEMON_OPTS
        if running ; then
            echo "$NAME."
        else
            echo " ERROR."
        fi
        ;;
  stop)
        echo -n "Stopping $DESC: "

        start-stop-daemon --stop --pidfile $PIDFILE || true

        echo "$NAME."

        ;;
  force-stop)
        echo -n "Forcefully stopping $DESC: "
        force_stop
        if ! running ; then
            echo "$NAME."
        else
            echo " ERROR."
        fi
        ;;

  force-reload)
        #
        # If the "reload" option is implemented, move the "force-reload"
        # option to the "reload" entry above. If not, "force-reload" is
        # just the same as "restart" except that it does nothing if the
        # daemon isn't already running.
        # check wether $DAEMON is running. If so, restart
        start-stop-daemon --stop --test --quiet --pidfile \
            /var/run/$NAME.pid --exec $DAEMON \
            && $0 restart \
            || exit 0
        ;;
  restart)
        echo -n "Restarting $DESC: "

        start-stop-daemon --stop --quiet --pidfile \
      $PIDFILE || true

        [ -n "$DODTIME" ] && sleep $DODTIME

        start-stop-daemon --start --quiet --pidfile $PIDFILE \
            --exec $DAEMON -- $DAEMON_OPTS || true

        ;;
  status)
    echo -n "$LABEL is "
    if running ;  then
        echo "running"
    else
        echo " not running."
        exit 1
    fi
    ;;
  *)
    N=/etc/init.d/$NAME
    # echo "Usage: $N {start|stop|restart|reload|force-reload}" >&2
    echo "Usage: $N {start|stop|restart|force-reload|status|force-stop}" >&2
    exit 1
    ;;
esac

exit 0
