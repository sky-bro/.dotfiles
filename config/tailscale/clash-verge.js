// Template: generate a ready-to-paste script with render-clash.py.
function main(config) {
  const tailscaleInterface = "__TAILSCALE_INTERFACE__";
  const magicDomain = "__MAGIC_DNS_SUFFIX__";
  if (tailscaleInterface.startsWith("__")) {
    throw new Error("Generate this script with render-clash.py before applying.");
  }
  if (config.dns && config.dns["fake-ip-filter-mode"] &&
      config.dns["fake-ip-filter-mode"] !== "blacklist") {
    throw new Error("This extension requires fake-ip-filter-mode: blacklist.");
  }
  const lan = "TAILSCALE-LAN";
  config.proxies = [
    ...(config.proxies || []).filter(proxy => proxy.name !== lan),
    {name: lan, type: "direct", "interface-name": tailscaleInterface},
  ];
  const networks = [
    "192.168.31.0/24", "192.168.5.0/24", "100.64.0.0/10",
    "fd7a:115c:a1e0::/48",
  ];
  config.tun = config.tun || {};
  config.tun["route-exclude-address"] = [...new Set([
    ...(config.tun["route-exclude-address"] || []), ...networks,
  ])];
  config.dns = config.dns || {};
  config.dns["fake-ip-filter"] = [...new Set([
    ...(config.dns["fake-ip-filter"] || ["*.lan", "*.local", "*.arpa"]),
    "+.home.k4i.top", `+.${magicDomain}`,
  ])];
  config.dns["nameserver-policy"] = {
    ...(config.dns["nameserver-policy"] || {}),
    "+.home.k4i.top": `udp://192.168.31.2:53#${lan}`,
    [`+.${magicDomain}`]: `udp://100.100.100.100:53#${lan}`,
  };
  const rules = [
    `DOMAIN-SUFFIX,home.k4i.top,${lan}`,
    `DOMAIN-SUFFIX,${magicDomain},${lan}`,
    ...networks.map(net => `${net.includes(":") ? "IP-CIDR6" : "IP-CIDR"},${net},${lan},no-resolve`),
  ];
  config.rules = [...rules, ...(config.rules || []).filter(rule => !rules.includes(rule))];
  return config;
}
