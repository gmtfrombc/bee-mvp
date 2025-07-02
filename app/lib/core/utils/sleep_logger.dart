// Lightweight sleep-debug logger that works in any build mode.
// To enable, build/run with:
//    --dart-define=SLEEP_DEBUG=true
// Only lines explicitly using `sLog` will appear; normal logs stay silent.

library;

const bool kSleepDebug = bool.fromEnvironment(
  'SLEEP_DEBUG',
  defaultValue: false,
);

void sLog(String msg) {
  if (kSleepDebug) {
    // Prefix makes it easy to grep: flutter logs | grep 'SLEEPDBG'
    // ignore: avoid_print
    print('SLEEPDBG $msg');
  }
}
