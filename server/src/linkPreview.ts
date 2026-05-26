export type LinkPreview = {
  url: string;
  title: string | null;
  description: string | null;
  imageUrl: string | null;
  domain: string;
};

const privateIpv4Ranges = [
  /^10\./,
  /^127\./,
  /^169\.254\./,
  /^172\.(1[6-9]|2\d|3[0-1])\./,
  /^192\.168\./,
  /^0\./
];

export function firstHttpUrl(text: string) {
  const match = text.match(/\bhttps?:\/\/[^\s<>"')]+/i);
  if (!match) return null;
  return match[0].replace(/[.,!?;:]+$/, '');
}

function isBlockedHost(hostname: string) {
  const host = hostname.toLowerCase();
  if (host === 'localhost' || host.endsWith('.localhost') || host.endsWith('.local')) return true;
  if (host === '::1' || host.startsWith('fc') || host.startsWith('fd')) return true;
  return privateIpv4Ranges.some((range) => range.test(host));
}

export function fallbackLinkPreview(rawUrl: string): LinkPreview | null {
  try {
    const url = new URL(rawUrl);
    if (url.protocol !== 'http:' && url.protocol !== 'https:') return null;
    return {
      url: url.toString(),
      title: null,
      description: null,
      imageUrl: null,
      domain: url.hostname.replace(/^www\./i, '')
    };
  } catch {
    return null;
  }
}

function decodeHtml(value: string) {
  return value
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/\s+/g, ' ')
    .trim();
}

function metaContent(html: string, key: string) {
  const escaped = key.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const byProperty = html.match(new RegExp(`<meta[^>]+(?:property|name)=["']${escaped}["'][^>]+content=["']([^"']+)["'][^>]*>`, 'i'));
  if (byProperty?.[1]) return decodeHtml(byProperty[1]);
  const byContentFirst = html.match(new RegExp(`<meta[^>]+content=["']([^"']+)["'][^>]+(?:property|name)=["']${escaped}["'][^>]*>`, 'i'));
  return byContentFirst?.[1] ? decodeHtml(byContentFirst[1]) : null;
}

function titleContent(html: string) {
  const match = html.match(/<title[^>]*>([\s\S]*?)<\/title>/i);
  return match?.[1] ? decodeHtml(match[1]) : null;
}

export async function fetchLinkPreview(rawUrl: string, options: { timeoutMs?: number; fetchImpl?: typeof fetch } = {}): Promise<LinkPreview | null> {
  const fallback = fallbackLinkPreview(rawUrl);
  if (!fallback) return null;

  const parsed = new URL(fallback.url);
  if (isBlockedHost(parsed.hostname)) return fallback;

  const fetchImpl = options.fetchImpl ?? fetch;
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), options.timeoutMs ?? 1500);
  try {
    const response = await fetchImpl(fallback.url, {
      redirect: 'follow',
      signal: controller.signal,
      headers: { 'user-agent': 'MyMessengerLinkPreview/0.6' }
    });
    const contentType = response.headers.get('content-type')?.toLowerCase() ?? '';
    if (!response.ok || !contentType.includes('text/html')) return fallback;
    const html = (await response.text()).slice(0, 262_144);
    const image = metaContent(html, 'og:image');
    return {
      ...fallback,
      title: metaContent(html, 'og:title') ?? titleContent(html),
      description: metaContent(html, 'og:description') ?? metaContent(html, 'description'),
      imageUrl: image ? new URL(image, fallback.url).toString() : null
    };
  } catch {
    return fallback;
  } finally {
    clearTimeout(timeout);
  }
}
