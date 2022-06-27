#!/usr/bin/env python3
import subprocess
import sys
import time

import watchdog.events
import watchdog.observers

try:
    assert sys.version_info >= (3, 8)
except AssertionError:
    sys.exit('Sorry. This script requires python3 >= 3.8 version')

DEFAULT_TIME_SLEEP = 60 * 10


def reload_nginx():
    command = ["/usr/sbin/nginx", "-s", "reload"]
    proc = subprocess.Popen(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        shell=False
    )
    e, out = proc.communicate()
    if e:
        output = e.decode('utf-8')
    else:
        output = out.decode('utf-8')
    return output


class Handler(watchdog.events.PatternMatchingEventHandler):
    def __init__(self):
        # Set the patterns for PatternMatchingEventHandler
        watchdog.events.PatternMatchingEventHandler.__init__(self, patterns=['*.conf'],
                                                             ignore_directories=True, case_sensitive=False)

    def on_created(self, event):
        print("Watchdog received created event - % s." % event.src_path, flush=True)
        # Event is created, you can process it now
        results = reload_nginx()
        print("Watchdog reload nginx - % s." % results, flush=True)

    def on_deleted(self, event):
        print("Watchdog received deleted event - % s." % event.src_path, flush=True)
        results = reload_nginx()
        print("Watchdog reload nginx - % s." % results, flush=True)


if __name__ == "__main__":
    watchdog_path = r"/etc/nginx/conf.d/"
    watchdog_upstream_path = r"/etc/nginx/upstreams/"
    event_handler = Handler()
    print("watch-dog start: src: {}".format(watchdog_path), flush=True)
    observer = watchdog.observers.Observer()
    observer.schedule(event_handler, path=watchdog_path, recursive=True)
    observer.schedule(event_handler, path=watchdog_upstream_path, recursive=True)
    observer.start()
    try:
        while True:
            time.sleep(DEFAULT_TIME_SLEEP)
    except KeyboardInterrupt:
        observer.stop()
    observer.join()
