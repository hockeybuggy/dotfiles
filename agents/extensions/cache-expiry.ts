import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const STATUS_KEY = "cache-expiry";

function formatRemaining(ms: number): string {
	const totalSeconds = Math.ceil(ms / 1000);
	const minutes = Math.floor(totalSeconds / 60);
	const seconds = totalSeconds % 60;
	return `${minutes}:${String(seconds).padStart(2, "0")}`;
}

export default function cacheExpiryExtension(pi: ExtensionAPI) {
	let expiresAt: number | undefined;
	let timer: ReturnType<typeof setInterval> | undefined;

	function ttlMs(ctx: ExtensionContext): number | undefined {
		const tier = process.env.PI_CACHE_RETENTION === "long" ? "long" : "short";
		const seconds = ctx.model?.promptCache?.[tier];
		return seconds ? seconds * 1000 : undefined;
	}

	function render(ctx: ExtensionContext) {
		const theme = ctx.ui.theme;
		if (expiresAt === undefined) {
			ctx.ui.setStatus(STATUS_KEY, undefined);
			return;
		}
		const remaining = expiresAt - Date.now();
		if (remaining <= 0) {
			ctx.ui.setStatus(STATUS_KEY, theme.fg("dim", "cache cold"));
			stopTimer();
			return;
		}
		ctx.ui.setStatus(STATUS_KEY, theme.fg("dim", `cache ${formatRemaining(remaining)}`));
	}

	function stopTimer() {
		if (timer) clearInterval(timer);
		timer = undefined;
	}

	function refresh(ctx: ExtensionContext) {
		const ttl = ttlMs(ctx);
		expiresAt = ttl === undefined ? undefined : Date.now() + ttl;
		stopTimer();
		if (expiresAt !== undefined) {
			timer = setInterval(() => render(ctx), 1000);
			timer.unref?.();
		}
		render(ctx);
	}

	pi.on("before_provider_request", (_event, ctx) => {
		if (ctx.hasUI) refresh(ctx);
	});

	pi.on("cache_warming_decision", (event, ctx) => {
		if (ctx.hasUI && event.action === "warm") refresh(ctx);
	});

	pi.on("model_select", (_event, ctx) => {
		expiresAt = undefined;
		stopTimer();
		if (ctx.hasUI) render(ctx);
	});

	pi.on("session_shutdown", () => stopTimer());
}
