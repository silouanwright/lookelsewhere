#!/usr/bin/env python3
"""Guest-only installation and live checks. Never operate the host shell."""
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess as sp
import sys
import time


def main():
    spec=importlib.util.spec_from_file_location('guest_guard',Path.home()/'guest-test.py')
    if not spec or not spec.loader or not (Path.home()/'guest-test.py').is_file():
        raise SystemExit('REFUSED: this adapter requires the managed VM and its guest guard')
    guard=importlib.util.module_from_spec(spec)
    spec.loader.exec_module(guard)
    guard.require_guest()
    guard.session_environment()
    os.environ['OMARCHY_PATH']='/usr/share/omarchy'
    root=Path(__file__).resolve().parents[2]
    plugin=Path.home()/'.config/omarchy/plugins/io.github.silouanwright.look-elsewhere'
    out=Path.home()/'test-results/look-elsewhere'
    out.mkdir(parents=True,exist_ok=True)
    os.environ['LOOKELSEWHERE_PLUGIN_DIR']=str(plugin)
    ipc=['quickshell','ipc','-n','-p','/usr/share/omarchy/shell']

    def run(args, timeout=150):
        return sp.check_output(args,stderr=sp.STDOUT,text=True,timeout=timeout)

    def panel_visible():
        return 'omarchy-keyboard-panel' in run(['hyprctl','layers','-j'])

    action=sys.argv[1]
    if action=='install':
        if plugin.exists():
            raise RuntimeError('Expected fresh guest without LookElsewhere installed')
        config=Path.home()/'.config/omarchy/shell.json'
        if config.exists(): shutil.copy2(config,out/'shell-before.json')
        shutil.copytree(root,plugin,ignore=shutil.ignore_patterns('tests','AGENTS.md','__pycache__','*.pyc'))
        print(run(['omarchy-shell','shell','rescanPlugins']))
        # Discovery is asynchronous; enable only after the shell knows this ID.
        deadline=time.monotonic()+30
        while time.monotonic()<deadline:
            catalog=run(['omarchy','plugin','list','--json'], timeout=5)
            (out/'plugin-catalog.json').write_text(catalog)
            if any(item.get('id')=='io.github.silouanwright.look-elsewhere'
                   for item in json.loads(catalog)):
                break
            time.sleep(.5)
        else:
            (out/'shell-discovery.log').write_text(run(['quickshell','log','-n','-p','/usr/share/omarchy/shell','--no-color']))
            raise RuntimeError('Plugin was not discovered within 30 seconds; see guest catalog and shell log')
        print(run(['omarchy','plugin','enable','io.github.silouanwright.look-elsewhere','--section','right']))
        deadline=time.monotonic()+30
        while time.monotonic()<deadline:
            try:
                status=run([*ipc,'call','look-elsewhere','status'])
                json.loads(status)
                print(status)
                break
            except (sp.SubprocessError,ValueError): time.sleep(.5)
        else: raise RuntimeError('Plugin IPC did not become ready')
        deadline=time.monotonic()+30
        while time.monotonic()<deadline:
            if 'target look-elsewhere-panel' in run([*ipc,'show']): break
            time.sleep(.5)
        (out/'shell-install.log').write_text(run(['quickshell','log','-n','-p','/usr/share/omarchy/shell','--no-color']))
        print(run(['bash',str(root/'tests/check-live-plugin.sh')]))
        (out/'packages.txt').write_text(run(['pacman','-Q']))
    elif action=='open':
        print(run([*ipc,'call','look-elsewhere-panel','open']))
        time.sleep(.5)
        if not panel_visible(): raise RuntimeError('Panel did not map')
    elif action=='dismissed':
        deadline=time.monotonic()+5
        while panel_visible() and time.monotonic()<deadline: time.sleep(.1)
        if panel_visible(): raise RuntimeError('Escape did not dismiss the panel')
        print('Native QMP Escape dismissed the mapped panel.')
    elif action=='reliability':
        for name in ('check-input-bounds.sh','check-live-reliability.sh'):
            output=run(['bash',str(root/'tests'/name)])
            (out/(name+'.log')).write_text(output)
            print(output)
        (out/'status.json').write_text(run([*ipc,'call','look-elsewhere','status']))
        (out/'diagnostics.json').write_text(run([*ipc,'call','look-elsewhere','diagnostics']))
        (out/'shell.log').write_text(run(['quickshell','log','-n','-p','/usr/share/omarchy/shell','--no-color']))
        print(run([*ipc,'call','look-elsewhere-panel','open']))
    else: raise SystemExit('Unknown guest action')


if __name__=='__main__':
    try: main()
    except sp.CalledProcessError as error:
        print(error.output,file=sys.stderr)
        raise
