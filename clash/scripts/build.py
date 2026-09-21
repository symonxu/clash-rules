#!/usr/bin/env python3
"""Build private profiles from the public source; never fetch/print credentials."""
import argparse, copy, json, os, re
from pathlib import Path
from urllib.parse import urlsplit, quote
import yaml
ROOT = Path(__file__).resolve().parents[2]

def check_nodes(config, nodes):
    names = [p['name'] for p in nodes]
    if len(set(names)) != len(names):
        raise ValueError('节点名重复，先修复订阅')
    counts = {}
    for group in config['proxy-groups']:
        if 'filter' in group:
            counts[group['name']] = sum(bool(re.search(group['filter'], n)) for n in names)
            if not counts[group['name']]:
                raise ValueError('筛选为空：' + group['name'])
    return counts

def build(provider, nodes, ref):
    c = yaml.safe_load((ROOT/'clash/common.yaml').read_text())
    u = urlsplit(provider['url'])
    if u.scheme != 'https' or not u.hostname or u.hostname == 'example.invalid':
        raise ValueError('需要有效的 HTTPS MESL 地址')
    counts = check_nodes(c, nodes)
    p = c['proxy-providers']['MESL-Nodes']
    p['url'] = provider['url']
    p['header']['User-Agent'] = [provider.get('user-agent', 'Stash/3.2.0')]
    for rp in c['rule-providers'].values():
        rp['url'] = rp['url'].replace('/symonxu/stash-rules/main/', '/symonxu/stash-rules/'+quote(ref,safe='/')+'/')
    ios = copy.deepcopy(c)
    mac = copy.deepcopy(c)
    mac['mixed-port'] = 7890
    mac['allow-lan'] = False
    # TUN and controller belong to Verge's UI, not the shared routing source.
    return {'XM-Clash-iOS.yaml':ios, 'XM-Clash-macOS.yaml':mac}, counts

def main():
    a = argparse.ArgumentParser(description=__doc__)
    a.add_argument('--provider', required=True, type=Path, help='Private JSON with url and optional user-agent')
    a.add_argument('--nodes', required=True, type=Path, help='MESL YAML for validating names; no nodes embedded')
    a.add_argument('--ref', default='main', help='GitHub branch/ref containing the public rule files')
    a.add_argument('--output', required=True, type=Path)
    args = a.parse_args()
    try:
        profiles, counts = build(json.loads(args.provider.read_text()), yaml.safe_load(args.nodes.read_text())['proxies'], args.ref)
        args.output.mkdir(parents=True,exist_ok=True,mode=0o700)
        for name,c in profiles.items():
            path=args.output/name
            # Stage privately then replace so a failed write preserves the previous profile.
            tmp=path.with_suffix('.tmp')
            fd=os.open(tmp,os.O_WRONLY|os.O_CREAT|os.O_TRUNC,0o600)
            os.fchmod(fd,0o600)
            with os.fdopen(fd,'w') as f:
                f.write(yaml.safe_dump(c,allow_unicode=True,sort_keys=False))
            os.replace(tmp,path)
        print(json.dumps({'profiles':list(profiles),'matching_nodes':counts},ensure_ascii=False))
    except Exception as e:
        # YAML/HTTP exceptions can contain credentials; do not dump them.
        raise SystemExit('生成失败（'+type(e).__name__+'）；请检查私有输入，未输出凭据。')
if __name__=='__main__': main()
