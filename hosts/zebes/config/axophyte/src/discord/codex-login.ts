import { ActionRowBuilder, ButtonBuilder, ButtonStyle, ComponentType, MessageFlags, Team } from "discord.js";
import type { ButtonInteraction, ChatInputCommandInteraction, InteractionCollector } from "discord.js";
import { loginCodex } from "../llm/client";
import { allowedMentions } from "./reply";

const LOGIN_TIMEOUT_MS = 10 * 60_000;
const CANCEL_ID = "codex_login_cancel";
let pending = false;

/** Bot-wide credentials belong to the application owner, not every server administrator. */
export async function codexLoginCommand(interaction: ChatInputCommandInteraction<"cached">): Promise<void> {
  const respond = (content: string) => interaction.editReply({ content, components: [], allowedMentions }).catch(() => {});
  let ownsApplication = false;
  try {
    const application = await interaction.client.application?.fetch();
    const owner = application?.owner;
    ownsApplication = !!owner && (owner instanceof Team ? owner.ownerId === interaction.user.id : owner.id === interaction.user.id);
  } catch { /* Fail closed if authenticated application ownership cannot be checked. */ }
  if (!ownsApplication) {
    await respond("Only the bot application owner can configure bot-wide Codex credentials.");
    return;
  }
  if (pending) {
    await respond("A Codex login is already in progress. Finish or cancel it before starting another.");
    return;
  }
  pending = true;
  const controller = new AbortController();
  let saving = false;
  let ended: "cancelled" | "timed out" | undefined;
  let collector: InteractionCollector<ButtonInteraction<"cached">> | undefined;
  let promptUpdate = Promise.resolve();
  let savingUpdate = Promise.resolve();
  const cancel = (reason: NonNullable<typeof ended>) => {
    if (saving || ended) return;
    ended = reason;
    collector?.stop(reason);
    controller.abort();
  };
  const timer = setTimeout(() => cancel("timed out"), LOGIN_TIMEOUT_MS);
  try {
    await loginCodex({
      signal: controller.signal,
      async onPrompt({ userCode, verificationUri }) {
        const promptMessage = interaction.editReply({
          content: `**Log into OpenAI Codex**\nVisit ${verificationUri} and enter code: \`${userCode}\`.\nThis connects a shared bot-wide subscription; configured-server admins can use its models. Approval replaces any saved Codex login.\nOnly approve this code if you requested it. This login closes after 10 minutes.\nDevice-code login must be enabled in ChatGPT Security settings or by your workspace administrator.`,
          components: [new ActionRowBuilder<ButtonBuilder>().addComponents(
            new ButtonBuilder().setStyle(ButtonStyle.Link).setLabel("Open OpenAI").setURL(verificationUri),
            new ButtonBuilder().setStyle(ButtonStyle.Secondary).setLabel("Cancel").setCustomId(CANCEL_ID),
          )],
          allowedMentions,
        });
        promptUpdate = promptMessage.then(() => {}, () => {});
        const message = await promptMessage;
        if (saving) return;
        controller.signal.throwIfAborted();
        collector = message.createMessageComponentCollector({ componentType: ComponentType.Button, filter: (button) => button.customId === CANCEL_ID });
        collector.on("collect", (button) => {
          if (button.user.id !== interaction.user.id) {
            void button.reply({ content: "Only the person who started this login can cancel it.", flags: MessageFlags.Ephemeral }).catch(() => {});
            return;
          }
          cancel("cancelled");
          void button.deferUpdate().catch(() => {});
        });
      },
      onSaving() {
        saving = true;
        ended = undefined;
        clearTimeout(timer);
        collector?.stop("saving");
        savingUpdate = promptUpdate.then(() => respond("Codex approved. Saving credentials; this step cannot be cancelled.")).then(() => {});
      },
    });
    await savingUpdate;
    await respond("Codex subscription connected. The active model is unchanged. Use /model to choose a Codex model.");
  } catch {
    await savingUpdate;
    await respond(saving
      ? "Couldn't confirm that Codex credentials were saved. The active model is unchanged. Check /model or try /codex-login again."
      : ended
        ? `Codex login ${ended}. Existing credentials and the active model are unchanged.`
        : "Couldn't complete Codex login. Existing credentials and the active model are unchanged. Ensure device-code login is enabled in ChatGPT Security settings or by your workspace administrator, then try /codex-login again.");
  } finally {
    clearTimeout(timer);
    collector?.stop("finished");
    controller.abort();
    pending = false;
  }
}
