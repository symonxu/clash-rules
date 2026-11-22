// 花云入口监控与告警脚本（适配 Clash.app 模块沙盒）
// 探测 3 个入口域名的代表节点可达性，并查询 0bc52bj8-10e0 公网最新入口 IP。

const STORE_KEY = "xm.flower.entry.monitor.v1";
const PROBE_URL = "https://www.gstatic.com/generate_204";
const DOH_BASE = "https://223.5.5.5/resolve";
const ENTRY_DOMAIN = "0bc52bj8-10e0.aws-agent.org";

const PROBES = [
  { label: "美6(e3585)", node: "🇺🇸 美国标准 IEPL 专线 6" },
  { label: "日3(e3585)", node: "🇯🇵 日本标准 IEPL 专线 3" },
  { label: "台2(fd025)", node: "🇨🇳 台湾高级 IEPL 专线 2" },
  { label: "德1(0bc52)", node: "🇩🇪 德国标准 IEPL 专线 1" },
];

function parseMode(arg) {
  if (typeof arg !== "string") return "panel";
  const m = arg.match(/mode=([a-z]+)/i);
  return m ? m[1].toLowerCase() : "panel";
}

function nowText() {
  return new Date().toLocaleTimeString("zh-CN", { hour12: false });
}

function probeNode(item, cb) {
  const t0 = Date.now();
  $httpClient.get(
    { url: PROBE_URL, node: item.node, timeout: 4 },
    (err, resp) => {
      const ms = Date.now() - t0;
      const ok = !err && resp && resp.status >= 200 && resp.status < 400;
      cb({
        label: item.label,
        ok,
        ms,
        detail: ok ? `${ms}ms` : "超时/失败",
      });
    }
  );
}

function queryEntryIP(cb) {
  const url = DOH_BASE + "?name=" + ENTRY_DOMAIN + "&type=A";
  $httpClient.get({ url, policy: "DIRECT", timeout: 4 }, (err, resp, body) => {
    if (err || !body) return cb("未知");
    try {
      const data = JSON.parse(body);
      const ans = Array.isArray(data.Answer)
        ? data.Answer.filter((a) => a.type === 1).map((a) => a.data)
        : [];
      cb(ans.length ? ans[0] : "无记录");
    } catch (_) {
      cb("解析异常");
    }
  });
}

function runAll(cb) {
  const results = new Array(PROBES.length);
  let pending = PROBES.length + 1;
  let publicIP = "未知";

  function tick() {
    pending -= 1;
    if (pending === 0) cb(results, publicIP);
  }

  PROBES.forEach((item, idx) => {
    probeNode(item, (res) => {
      results[idx] = res;
      tick();
    });
  });

  queryEntryIP((ip) => {
    publicIP = ip;
    tick();
  });
}

const mode = parseMode(typeof $argument === "string" ? $argument : "");
let finished = false;
function finish(payload) {
  if (finished) return;
  finished = true;
  payload !== undefined ? $done(payload) : $done();
}

runAll((results, publicIP) => {
  const failed = results.filter((r) => !r.ok);
  const okCount = results.length - failed.length;
  const line = results.map((r) => `${r.label}:${r.detail}`).join(" | ");
  const ts = nowText();

  let prevFailed = false;
  try {
    const prevRaw = $persistentStore.read(STORE_KEY);
    if (prevRaw) prevFailed = Boolean(JSON.parse(prevRaw).failedCount);
  } catch (_) {}

  try {
    $persistentStore.write(
      JSON.stringify({ ts, failedCount: failed.length, line, publicIP }),
      STORE_KEY
    );
  } catch (_) {}

  if (mode === "cron" || mode === "network") {
    if (failed.length > 0) {
      const names = failed.map((r) => r.label).join("、");
      $notification.post(
        "花云入口异常告警",
        `${names} 探测失败（${okCount}/${results.length} 可用）`,
        `0bc52bj8 公网解析: ${publicIP}\n${line}`
      );
    } else if (prevFailed) {
      $notification.post(
        "花云入口已恢复",
        `全部 ${results.length} 条代表节点正常`,
        `0bc52bj8 公网解析: ${publicIP}\n${line}`
      );
    }
    console.log(`[flower-entry-monitor:${mode}] ${line} | 0bc52bj8=${publicIP}`);
    finish();
    return;
  }

  const title =
    failed.length === 0
      ? `花云入口正常 (${okCount}/${results.length})`
      : `花云入口异常 (${okCount}/${results.length} 可用)`;
  const content = `${line}\n0bc52bj8 公网: ${publicIP} · ${ts}`;
  finish({ title, content });
});
