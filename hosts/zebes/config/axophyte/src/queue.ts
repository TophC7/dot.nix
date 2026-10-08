type MessageJob = { state: "queued" | "running"; rerun: boolean };

export class TurnQueue {
  private chain: Promise<void> = Promise.resolve();
  private readonly messages = new Map<string, MessageJob>();

  message(threadId: string, run: () => Promise<void>): void {
    const existing = this.messages.get(threadId);
    if (existing) {
      if (existing.state === "running") existing.rerun = true;
      return;
    }

    const job: MessageJob = { state: "queued", rerun: false };
    this.messages.set(threadId, job);
    const enqueue = () => {
      void this.command(async () => {
        job.state = "running";
        try {
          await run();
        } finally {
          if (job.rerun) {
            job.rerun = false;
            job.state = "queued";
            enqueue();
          } else {
            this.messages.delete(threadId);
          }
        }
      });
    };
    enqueue();
  }

  command<T>(run: () => Promise<T>): Promise<T> {
    const result = this.chain.then(run);
    this.chain = result.then(
      () => {},
      () => console.error("turn queue job failed"),
    );
    return result;
  }
}
