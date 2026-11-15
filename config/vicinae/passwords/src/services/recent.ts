import { createHash } from "node:crypto";
export type RecentEntry = { name: string; fieldId: string; type: string; timestamp: number };
export type RecentStorage = { get(key: string): Promise<string | undefined>; set(key: string, value: string): Promise<void> };
export class RecentEntries {
  private key: string;
  private storage: RecentStorage;
  readonly seconds: number;
  constructor(store: string, storage: RecentStorage, seconds = 120) {
    this.key = `recent:${createHash("sha256").update(store).digest("hex")}`;
    this.storage = storage; this.seconds = Number.isFinite(seconds) && seconds > 0 ? seconds : 0;
  }
  async get(now = Date.now()): Promise<RecentEntry | undefined> {
    if (!this.seconds) return;
    try {
      const value = JSON.parse(await this.storage.get(this.key) || "null") as RecentEntry;
      if (value && typeof value.name === "string" && typeof value.fieldId === "string" && typeof value.type === "string" && Number.isFinite(value.timestamp) && value.timestamp <= now && now - value.timestamp < this.seconds * 1000) return value;
    } catch { /* malformed or unavailable cache must not break password access */ }
  }
  async record(name: string, fieldId: string, type: string, now = Date.now()) {
    if (!this.seconds) return;
    // Only navigation metadata is stored. Values, OTP URIs and codes never enter
    // this API, so adding fields cannot accidentally persist their secrets.
    try { await this.storage.set(this.key, JSON.stringify({ name, fieldId, type, timestamp: now })); } catch { }
  }
}
