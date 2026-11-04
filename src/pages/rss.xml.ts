import type { APIRoute } from 'astro';
import { site } from '../config/site';
import { posts, rssFeed } from '../data/posts';

export const GET: APIRoute = () => {
  const feed = rssFeed({
    siteUrl: site.url,
    feedPath: '/rss.xml',
    title: 'DatabaseDeveloper insights',
    link: `${site.url}/insights`,
    description: site.description,
    author: site.personName,
    items: posts
  });
  return new Response(feed, { headers: { 'Content-Type': 'application/rss+xml; charset=utf-8' } });
};
