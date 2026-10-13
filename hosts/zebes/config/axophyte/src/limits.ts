export const limits = {
  maxOutputTokens: 8192,
  summaryMaxTokens: 6144,
  contextHeadroomTokens: 1024,
  maxSummaryChars: 8000,
  maxImagesPerRequest: 4,
  maxImageBytes: 10 * 1024 * 1024,
  imageMaxSide: 1536,
  /** Loaded media kept in memory across turns, oldest evicted first. */
  mediaCacheEntries: 64,
  /** Per prompt, newest first: files read as text and transcripts; images above include stills grids. */
  maxDocumentsPerRequest: 4,
  maxTranscriptsPerRequest: 2,
  maxVideoBytes: 50 * 1024 * 1024,
  maxAudioBytes: 25 * 1024 * 1024,
  maxDocumentBytes: 25 * 1024 * 1024,
  maxTextBytes: 1024 * 1024,
  documentChars: 8000,
  transcriptChars: 4000,
  /** Only the first this-many seconds of audio are transcribed. */
  transcribeSeconds: 180,
  pdfPages: 30,
  downloadTimeoutMs: 60_000,
  processTimeoutMs: 60_000,
  whisperTimeoutMs: 180_000,
  promptEmoji: 100,
  /** Longest emoji description, whether the model's or an admin's. */
  emojiNoteChars: 200,
  toolBudgets: { self_info: 1, web_search: 3, open_url: 3, search_server: 3, read_conversation: 2, remember: 4, revise: 4, react: 3, draw: 1 },
  maxToolRounds: 6,
  /** Rounds after maxToolRounds whose tool calls are refused, prompting a plain answer. */
  answerRetries: 2,
  searchResultCount: 5,
  maxQueryChars: 400,
  editIntervalMs: 1200,
  splitAt: 1900,
  typingIntervalMs: 8000,
  /** Silence before the reply slot shows what Axophyte is doing. */
  statusNoticeMs: 15_000,
  llmIdleTimeoutMs: 600_000,
  /** How far back a conversation's first load reaches, when Axophyte joins one already underway. */
  firstLoadMessages: 300,
  channelContextMessages: 20,
  channelContextMaxAgeMs: 30 * 60_000,
  replyChainDepth: 10,
  /** Recent messages /retry scans for the newest human one; one Discord page. */
  retryScanMessages: 100,
  burstQuietMs: 4000,
  burstTypingMs: 10_000,
  burstMaxWaitMs: 45_000,
  personMemoryChars: 2000,
  pruneTargetChars: 1200,
  maxFactChars: 300,
  maxPageChars: 12_000,
  serverHits: 8,
  conversationChars: 4000,
  /** Drawing: SVG size cap, PNG width, resvg deadline, per-pass output, prompt clips, remembered channels. */
  artMaxSvgChars: 60_000,
  artRenderWidth: 1024,
  artRenderTimeoutMs: 20_000,
  artMaxTokens: 8192,
  artPromptChars: 1500,
  artRequestChars: 3000,
  artMemoryChannels: 50,
} as const;


