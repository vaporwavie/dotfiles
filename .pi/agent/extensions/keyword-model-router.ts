import { CustomEditor, type ExtensionAPI, type ExtensionContext } from "@mariozechner/pi-coding-agent";
import { Text, matchesKey, truncateToWidth, visibleWidth } from "@mariozechner/pi-tui";

type ThinkingLevel = "off" | "minimal" | "low" | "medium" | "high" | "xhigh";

type Route = {
	provider: string;
	model: string;
	thinkingLevel: ThinkingLevel;
	label: string;
	status: string;
};

type RouteSpec = {
	route: Route;
	pattern: RegExp;
	highlightColor: number;
	hints: string[];
};

const DEFAULT_ROUTE: Route = {
	provider: "openai-codex",
	model: "gpt-5.4",
	thinkingLevel: "xhigh",
	label: "Deep",
	status: "auto:deep/xhigh",
};

const UI_ROUTE: Route = {
	provider: "anthropic",
	model: "claude-opus-4-6",
	thinkingLevel: "high",
	label: "Artisan",
	status: "auto:artisan/high",
};

const CODEGEN_ROUTE: Route = {
	provider: "openai-codex",
	model: "gpt-5.3-codex-spark",
	thinkingLevel: "low",
	label: "Flash",
	status: "auto:flash/low",
};

const EASY_ROUTE: Route = {
	provider: "openai-codex",
	model: "gpt-5.4-mini",
	thinkingLevel: "high",
	label: "Smart",
	status: "auto:smart/high",
};

const ROUTE_SPECS: RouteSpec[] = [
	{
		route: UI_ROUTE,
		pattern: /\b(ui|ux|layout|frontend|user\s+interfaces?|css|styling|tailwind|component\s+design)\b/i,
		highlightColor: 110,
		hints: ["ui", "ux", "layout", "frontend", "user interface", "css", "styling", "tailwind", "component design"],
	},
	{
		route: CODEGEN_ROUTE,
		pattern: /\b(codegen|rename|renaming|bulk\s+rename|mass\s+rename|find.and.replace)\b/i,
		highlightColor: 178,
		hints: ["codegen", "rename", "renaming", "bulk rename", "mass rename", "find and replace"],
	},
	{
		route: EASY_ROUTE,
		pattern: /\b(quick|simple|trivial|easy|minor|small\s+fix|typo|one.liner)\b/i,
		highlightColor: 108,
		hints: ["quick", "simple", "trivial", "easy", "minor", "small fix", "typo", "one-liner"],
	},
];

type MatchedRoute = { spec: RouteSpec; keyword: string } | undefined;

function matchRoute(text: string): MatchedRoute {
	for (const spec of ROUTE_SPECS) {
		const match = text.match(spec.pattern);
		if (match) return { spec, keyword: match[0] };
	}

	return undefined;
}

function colorize(text: string, color: number, bold = false): string {
	const open = `${bold ? "\x1b[1m" : ""}\x1b[38;5;${color}m`;
	const close = `\x1b[39m${bold ? "\x1b[22m" : ""}`;
	return `${open}${text}${close}`;
}

function highlightForMatch(text: string, match: MatchedRoute): string {
	if (!match) return text;
	return text.replace(new RegExp(match.spec.pattern.source, "gi"), (value) => colorize(value, match.spec.highlightColor, true));
}

function formatRouteHint(spec: RouteSpec): string {
	return `${colorize(spec.route.label, spec.highlightColor, true)} ← ${spec.hints.join(", ")}`;
}

function formatDefaultHint(): string {
	return `\x1b[1m${DEFAULT_ROUTE.label}\x1b[22m ← default (no route keywords)`;
}

async function showModelRoutingHelp(ctx: ExtensionContext): Promise<void> {
	if (!ctx.hasUI) return;

	await ctx.ui.custom<void>((_tui, theme, _keybindings, done) => {
		const content = new Text(
			[
				theme.fg("dim", "Model routing · first matching group wins"),
				...ROUTE_SPECS.map(formatRouteHint),
				formatDefaultHint(),
				"",
				theme.fg("dim", "Press Enter or Esc to close"),
			].join("\n"),
			1,
			1,
		);

		return {
			render: (width: number) => content.render(width),
			invalidate: () => content.invalidate(),
			handleInput: (data: string) => {
				if (matchesKey(data, "enter") || matchesKey(data, "escape")) {
					done(undefined);
				}
			},
		};
	});
}

class KeywordRouteEditor extends CustomEditor {
	private readonly editorTheme: ConstructorParameters<typeof CustomEditor>[1];

	constructor(...args: ConstructorParameters<typeof CustomEditor>) {
		super(...args);
		this.editorTheme = args[1];
	}

	render(width: number): string[] {
		const match = matchRoute(this.getText());
		const lines = super.render(width).map((line) => highlightForMatch(line, match));
		if (lines.length === 0 || this.isShowingAutocomplete()) return lines;

		const label = match
			? colorize(` ${match.spec.route.label} `, match.spec.highlightColor, true)
			: this.editorTheme.borderColor(` ${DEFAULT_ROUTE.label} `);
		const labelWidth = visibleWidth(label);
		const lastLineIndex = lines.length - 1;
		const lastLine = lines[lastLineIndex]!;

		if (labelWidth >= width) {
			lines[lastLineIndex] = truncateToWidth(label, width, "");
			return lines;
		}

		lines[lastLineIndex] = truncateToWidth(lastLine, width - labelWidth, "") + label;
		return lines;
	}
}

export default function keywordModelRouter(pi: ExtensionAPI) {
	if (process.env.PI_SUBAGENT_CHILD === "1") return;

	pi.registerCommand("model-routing", {
		description: "Show model routing aliases and trigger keywords",
		handler: async (_args, ctx) => {
			await showModelRoutingHelp(ctx);
		},
	});

	const warned = new Set<string>();

	function warnOnce(ctx: ExtensionContext, key: string, message: string) {
		if (warned.has(key)) return;
		warned.add(key);
		console.warn(message);
		ctx.ui.notify(message, "warning");
	}

	async function applyRoute(ctx: ExtensionContext, route: Route, keyword?: string): Promise<boolean> {
		const targetModelKey = `${route.provider}/${route.model}`;
		const currentModelKey = ctx.model ? `${ctx.model.provider}/${ctx.model.id}` : undefined;

		if (currentModelKey !== targetModelKey) {
			const model = ctx.modelRegistry.find(route.provider, route.model);
			if (!model) {
				warnOnce(ctx, `missing:${targetModelKey}`, `Keyword model router: model ${targetModelKey} was not found.`);
				return false;
			}

			const success = await pi.setModel(model);
			if (!success) {
				warnOnce(
					ctx,
					`auth:${targetModelKey}`,
					`Keyword model router: no credentials are available for ${targetModelKey}.`,
				);
				return false;
			}
		}

		if (pi.getThinkingLevel() !== route.thinkingLevel) {
			pi.setThinkingLevel(route.thinkingLevel);
		}

		ctx.ui.setStatus("keyword-model-router", route.status);

		if (keyword && currentModelKey !== targetModelKey) {
			ctx.ui.notify(`Auto-switched to ${route.label} for "${keyword}".`, "info");
		}

		return true;
	}

	pi.on("session_start", async (event, ctx) => {
		ctx.ui.setStatus("keyword-model-router", DEFAULT_ROUTE.status);
		ctx.ui.setEditorComponent((tui, theme, keybindings) => new KeywordRouteEditor(tui, theme, keybindings));

		if (ctx.hasUI && (event.reason === "startup" || event.reason === "reload")) {
			ctx.ui.notify("This harness is configured to route models per keyword. Run /model-routing to learn more.", "info");
		}
	});

	pi.on("input", async (event, ctx) => {
		if (event.source === "extension") {
			return { action: "continue" };
		}

		const match = matchRoute(event.text);
		if (match) {
			const routed = await applyRoute(ctx, match.spec.route, match.keyword);
			if (!routed) await applyRoute(ctx, DEFAULT_ROUTE);
		} else {
			await applyRoute(ctx, DEFAULT_ROUTE);
		}

		return { action: "continue" };
	});
}
