import { Buffer } from "node:buffer";

// Expose Buffer globally so esm.sh-compiled packages (e.g., storage-js) work
// deno-lint-ignore no-explicit-any
(globalThis as any).Buffer = Buffer;

// Minimal NodeJS namespace to satisfy types that reference NodeJS.ProcessEnv
declare global {
  namespace NodeJS {
    // deno-lint-ignore no-empty-interface
    interface ProcessEnv {}
  }
}
