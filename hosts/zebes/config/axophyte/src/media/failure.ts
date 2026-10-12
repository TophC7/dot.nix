export class MediaFailure extends Error {
  constructor(
    message: string,
    readonly retryable = false,
    readonly detail: " - unsupported" | " - too large" = " - unsupported",
  ) {
    super(message);
    this.name = "MediaFailure";
  }
}
