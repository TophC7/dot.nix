import { TurnAborted } from "./llm/model";

export function throwIfAborted(signal?: AbortSignal): void {
  if (signal?.aborted) throw new TurnAborted();
}

/** Cancel this waiter, not the shared work behind its promise. */
export function abortWait<T>(promise: Promise<T>, signal?: AbortSignal): Promise<T> {
  if (!signal) return promise;
  return new Promise<T>((resolve, reject) => {
    const abort = () => {
      signal.removeEventListener("abort", abort);
      reject(new TurnAborted());
    };
    promise.then(
      (value) => { signal.removeEventListener("abort", abort); resolve(value); },
      (error: unknown) => { signal.removeEventListener("abort", abort); reject(error); },
    );
    signal.addEventListener("abort", abort, { once: true });
    if (signal.aborted) abort();
  });
}
