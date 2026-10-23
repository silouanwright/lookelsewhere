"""Exercise the current LookElsewhere checkout only inside the managed guest."""
BUILD = []
PAYLOAD = ['BarWidget.qml','BrowserContext.qml','Model.js','NativeAlerts.qml','Overlay.qml',
           'Service.qml','Ui','Views','assets','browser-extension','manifest.json','tools',
           'vendor','tests','LICENSE','THIRD_PARTY_NOTICES.md']


def run(h):
    h.logged('guest-install','python3 ~/look-elsewhere/tests/vm/guest.py install')
    h.record('guest-install',True)
    h.client('intent','start','--test-result-id',h.agent,'--message','LookElsewhere panel keyboard dismissal')
    h.logged('panel-open','python3 ~/look-elsewhere/tests/vm/guest.py open')
    h.screenshot('panel-open')
    h.client('send-keys','--keys','<ESC>')
    h.logged('panel-dismissed','python3 ~/look-elsewhere/tests/vm/guest.py dismissed')
    h.record('native-qmp-panel-dismissal',True)
    h.client('intent','end')
    h.logged('reliability','python3 ~/look-elsewhere/tests/vm/guest.py reliability',timeout=240)
    h.record('live-reliability',True)
    h.screenshot('panel-after-reliability')
