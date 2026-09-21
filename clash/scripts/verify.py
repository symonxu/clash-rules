#!/usr/bin/env python3
"""Verify exact routing equivalence to 3.2 and references, without network traffic."""
import copy, ipaddress, json
from pathlib import Path
import yaml
from build import check_nodes, build
ROOT=Path(__file__).resolve().parents[2]
b=yaml.safe_load((ROOT/'个人网络分流3.2.stoverride').read_text())
c=yaml.safe_load((ROOT/'clash/common.yaml').read_text())
expanded=[]
for r in c['rules']:
    p=r.split(',')
    if p[0]=='RULE-SET' and p[1].startswith('XM32-'):
        rp=c['rule-providers'][p[1]]
        assert rp['behavior']=='classical' and rp['format']=='yaml'
        assert rp['url'].endswith('/clash/rules/'+p[1]+'.yaml')
        for pred in yaml.safe_load((ROOT/'clash/rules'/(p[1]+'.yaml')).read_text())['payload']:
            parts=pred.split(',');expanded.append(','.join(parts[:2]+[p[2]]+parts[2:]))
    else: expanded.append(r)
assert expanded==b['rules'], 'Rule content/order drifted'
assert len(expanded)==153
for k,v in b['dns'].items(): assert c['dns'][k]==v
names=[g['name'] for g in c['proxy-groups']]
assert len(names)==len(set(names))==9
assert names==[g['name'] for g in b['proxy-groups']]
assert len({p['path'] for p in c['rule-providers'].values()})==len(c['rule-providers'])
for old,g in zip(b['proxy-groups'],c['proxy-groups']):
    for k in ('name','type','use','proxies','filter','lazy'): assert old.get(k)==g.get(k),(g['name'],k)
    assert g['empty-fallback']=='REJECT'
    for p in g.get('proxies',[]): assert p in names
    for p in g.get('use',[]): assert p in c['proxy-providers']
    if g['type']=='select': assert g['interval']==0 and 'url' not in g
    else: assert g['interval']==300 and g['url']=='http://www.apple.com'
for r in c['rules']:
    p=r.split(',');assert p[-1] in names+['DIRECT','REJECT']
    if p[0]=='RULE-SET': assert p[1] in c['rule-providers']
# Detect group dependency cycles.
def walk(name,seen):
    assert name not in seen
    for child in next(g for g in c['proxy-groups'] if g['name']==name).get('proxies',[]): walk(child,seen|{name})
for n in names: walk(n,set())
# Check the explicit domain boundary before generic CN lists/GEOIP; no public DNS requests.
def route(domain):
    for r in expanded:
        t,v,target,*_=r.split(',') if ',' in r and not r.startswith('MATCH,') else ('MATCH','',r.split(',')[-1])
        if (t=='DOMAIN' and v==domain) or (t=='DOMAIN-SUFFIX' and (domain==v or domain.endswith('.'+v))) or (t=='DOMAIN-KEYWORD' and v in domain): return target
    return None
cases={'api.hyperliquid.xyz':'💰 Web3交易','bsc-dataseed.binance.org':'⛓️ Web3链上数据','api.mainnet-beta.solana.com':'⛓️ Web3链上数据','chatgpt.com':'🤖 AI工具','gemini.google.com':'🤖 AI工具','generativelanguage.googleapis.com':'🤖 AI工具','www.google.com':'🔎 Google服务','apple-relay.apple.com':'🤖 AI工具','push.apple.com':'🌐 日常上网','apps.apple.com':'DIRECT','swcdn.apple.com':'DIRECT','www.douyin.com':'DIRECT'}
for domain,target in cases.items(): assert route(domain)==target,domain
try: check_nodes(c,[{'name':'无匹配地区'}])
except ValueError: pass
else: raise AssertionError('Empty pools accepted')
# Rendering must keep platform differences out of shared rules and preserve the private provider.
fixtures=[{'name':n} for n in ['🇯🇵 日本 01','🇯🇵 日本 08 家宽','🇸🇬 新加坡 01']]
profiles,_=build({'url':'https://provider.test/private'},fixtures,'feat/mihomo-hako-3.2')
a=profiles['XM-Clash-macOS.yaml'];i=profiles['XM-Clash-iOS.yaml'];a.pop('mixed-port');a.pop('allow-lan');assert a==i
print(json.dumps({'baseline_rules':len(expanded),'groups':len(names),'domain_cases':len(cases),'empty_pool_guard':'passed','reference_order_equivalence':'passed'},ensure_ascii=False))
