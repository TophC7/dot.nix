import { limits } from "../limits";

export class ModelError extends Error {
  constructor(public kind: "not_loaded" | "too_long" | "unavailable" | "timeout", message: string) {
    super(message);
    this.name = "ModelError";
  }
}

export type ModelChoice = { id: string; contextSize: number };
export type ModelSession = {
  choice: ModelChoice;
  call<T>(operation: (choice: ModelChoice) => Promise<T>): Promise<T>;
};
export class TurnAborted extends Error {}

// One retry covers selection, preparation, summarizing, and generation together.
export async function modelSession(pick: () => Promise<ModelChoice>): Promise<ModelSession> {
  let retried = false;
  let choice: ModelChoice;
  try { choice = await pick(); }
  catch (error) {
    if (!(error instanceof ModelError) || error.kind !== "not_loaded") throw error;
    retried = true;
    choice = await pick();
  }
  const session: ModelSession = {
    choice,
    async call<T>(operation: (choice: ModelChoice) => Promise<T>): Promise<T> {
      try { return await operation(session.choice); }
      catch (error) {
        if (!(error instanceof ModelError) || error.kind !== "not_loaded" || retried) throw error;
        retried = true;
        session.choice = await pick();
        return operation(session.choice);
      }
    },
  };
  return session;
}

export function promptBudget(contextSize: number, outputTokens: number = limits.maxOutputTokens): number {
  return contextSize - outputTokens - limits.contextHeadroomTokens;
}

export function effectiveContextSize(value: unknown): number {
  if (typeof value !== "number" || !Number.isSafeInteger(value) || value <= limits.maxOutputTokens + limits.contextHeadroomTokens) {
    throw new RangeError("model server returned an invalid or insufficient runtime context");
  }
  return value;
}
