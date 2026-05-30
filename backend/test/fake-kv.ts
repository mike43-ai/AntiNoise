// Minimal in-memory KVNamespace stand-in for rate-limiter tests. Implements only
// the get/put surface peekUsage/commitUsage touch; ignores TTL semantics (no
// expiry simulation needed for synchronous unit assertions).
export function fakeKV(): KVNamespace & { store: Map<string, string> } {
  const store = new Map<string, string>();
  const kv = {
    store,
    async get(key: string): Promise<string | null> {
      return store.has(key) ? store.get(key)! : null;
    },
    async put(key: string, value: string): Promise<void> {
      store.set(key, value);
    },
    async delete(key: string): Promise<void> {
      store.delete(key);
    },
  };
  // Cast through unknown — we deliberately implement only the used subset.
  return kv as unknown as KVNamespace & { store: Map<string, string> };
}
