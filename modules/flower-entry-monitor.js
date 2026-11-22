// 花云入口监控与告警脚本（通过 Clash.app 本机外部控制器接口获取单节点真实延迟）
// 避免主进程 $httpClient 忽略 node 参数导致全部复用当前默认出口的问题。

const STORE_KEY = "xm.flower.entry.monitor.v1";
const CONTROLLER_BASE = "http://127.0.0.1:9090";
const PROBE_URL = "https://www.gstatic.com/generate_204";
const DOH_BASE = "https://223.5.5.5/resolve";
const ENTRY_DOMAIN = "0bc52bj8-10e0.aws-agent.org";

const PROBES = [
  { label: "美6(e3585)", node: "🇺🇸 美国标准 IEPL 专线 6" },
  { label: "日3(e3585)", node: "🇯🇵 日本标准 IEPL 专线 3" },
  { label: "台2(fd025)", node: "🇨🇳 台湾高级 IEPL 专线 2" },
  { label: "德1(0bc52)", node: "🇩🇪 德国标准 IEPL 专线 1" },
];

function parseArg(arg) {
  if (typeof arg !== "string") return { mode: "panel", secret: "" };
  const m = arg.match(/mode=([a-z]+)/i);
  const mode = m ? m[1].toLowerCase() : "panel";
  const sIdx = arg.indexOf("secret=");
  let secret = sIdx >= 0 ? arg.slice(sIdx + 7).trim() : "";
  if (secret === "{{{控制密钥}}}") secret = "";
  return { mode, secret };
}

function nowText() {
  return new Date().toLocaleTimeString("zh-CN", { hour12: false });
}

function probeNodeViaController(item, secret, cb) {
  const url =
    CONTROLLER_BASE +
    "/proxies/" +
    encodeURIComponent(item.node) +
    "/delay?timeout=4000&url=" +
    encodeURIComponent(PROBE_URL);

  $httpClient.get(
    {
      url,
      headers: { Authorization: "Bearer " + secret },
      timeout: 5,
    },
    (err, resp, body) => {
      const status = resp && typeof resp.status === "number" ? resp.status : 0;
      if (status === 200 && body) {
        try {
          const data = JSON.parse(body);
          if (data && typeof data.delay === "number" && data.delay > 0) {
            return cb({
              label: item.label,
              ok: true,
              kind: "ok",
              ms: data.delay,
              detail: `${data.delay}ms`,
            });
          }
        } catch (_) {}
      }
      if (status === 401 || status === 403) {
        return cb({ label: item.label, ok: false, kind: "auth", detail: "密钥无效" });
      }
      if (status === 404) {
        return cb({ label: item.label, ok: false, kind: "missing", detail: "无此节点" });
      }
      if (status === 0) {
        return cb({
          label: item.label,
          ok: false,
          kind: "conn",
          detail: err ? String(err) : "控制器不可达",
        });
      }
      return cb({ label: item.label, ok: false, kind: "timeout", detail: "超时/失败" });
    }
  );
}

function probeCurrentRoute(cb) {
  const t0 = Date.now();
  $httpClient.get({ url: PROBE_URL, timeout: 4 }, (err, resp) => {
    const ms = Date.now() - t0;
    const ok = !err && resp && resp.status >= 200 && resp.status < 400;
    cb(ok ? `${ms}ms` : "超时");
  });
}

function queryEntryIP(cb) {
  const url = DOH_BASE + "?name=" + ENTRY_DOMAIN + "&type=A";
  $httpClient.get({ url, timeout: 4 }, (err, resp, body) => {
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

function runWithSecret(secret, cb) {
  const results = new Array(PROBES.length);
  let pending = PROBES.length + 1;
  let publicIP = "未知";

  function tick() {
    pending -= 1;
    if (pending === 0) cb(results, publicIP);
  }

  PROBES.forEach((item, idx) => {
    probeNodeViaController(item, secret, (res) => {
      results[idx] = res;
      tick();
    });
  });

  queryEntryIP((ip) => {
    publicIP = ip;
    tick();
  });
}

function runWithoutSecret(cb) {
  let pending = 2;
  let routeDetail = "未知";
  let publicIP = "未知";

  function tick() {
    pending -= 1;
    if (pending === 0) cb(routeDetail, publicIP);
  }

  probeCurrentRoute((detail) => {
    routeDetail = detail;
    tick();
  });

  queryEntryIP((ip) => {
    publicIP = ip;
    tick();
  });
}

const { mode, secret } = parseArg(typeof $argument === "string" ? $argument : "");
let finished = false;
function finish(payload) {
  if (finished) return;
  finished = true;
  payload !== undefined ? $done(payload) : $done();
}

if (!secret) {
  runWithoutSecret((routeDetail, publicIP) => {
    const ts = nowText();
    if (mode === "cron" || mode === "network") {
      console.log(
        `[flower-entry-monitor:${mode}] missing secret; current=${routeDetail} | 0bc52bj8=${publicIP}`
      );
      finish();
      return;
    }
    finish({
      title: "花云入口待填控制密钥",
      content: `请在模块「设置 › 控制密钥」填入本机外部控制器密钥\n当前出口:${routeDetail} | 0bc52bj8:${publicIP} · ${ts}`,
    });
  });
} else {
  runWithSecret(secret, (results, publicIP) => {
    const ts = nowText();
    const authError = results.some((r) => r.kind === "auth");
    const controllerDown = results.every((r) => r.kind === "conn");

    if (authError) {
      if (mode === "cron" || mode === "network") {
        console.log(`[flower-entry-monitor:${mode}] controller auth failed (401/403)`);
        finish();
        return;
      }
      finish({
        title: "花云控制密钥无效",
        content: `请核对模块「设置 › 控制密钥」与外部控制器密钥是否一致\n0bc52bj8 公网: ${publicIP} · ${ts}`,
      });
      return;
    }

    if (controllerDown) {
      if (mode === "cron" || mode === "network") {
        console.log(
          `[flower-entry-monitor:${mode}] controller unreachable: ${results[0].detail}`
        );
        finish();
        return;
      }
      finish({
        title: "外部控制器未连接",
        content: `无法连到 127.0.0.1:9090（${results[0].detail}）\n0bc52bj8 公网: ${publicIP} · ${ts}`,
      });
      return;
    }

    const failed = results.filter((r) => !r.ok);
    const okCount = results.length - failed.length;
    const line = results.map((r) => `${r.label}:${r.detail}`).join(" | ");

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
}
