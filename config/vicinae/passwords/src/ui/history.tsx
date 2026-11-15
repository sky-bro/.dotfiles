import { Detail } from "@vicinae/api";
import { useEffect, useState } from "react";
import type { Entry } from "../domain/entry.ts";
import { useRuntime } from "./runtime.tsx";
export function History({ entry }: { entry?: Entry }) {
  const { store } = useRuntime(); const [text, setText] = useState("Loading history…");
  useEffect(() => {
    let active = true;
    void store.history(entry).then((value) => { if (active) setText(value || "No commits found."); })
      .catch(() => { if (active) setText("No Git history available. Open the store terminal to inspect Git configuration."); });
    return () => { active = false; };
  }, [entry, store]);
  return <Detail navigationTitle="Password History" markdown={`\`\`\`text\n${text.replaceAll("`", "ˋ")}\n\`\`\``} />;
}
