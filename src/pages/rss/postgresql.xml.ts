import type { APIRoute } from 'astro';
import { site } from '../../config/site';
import { posts, rssFeed } from '../../data/posts';

// PostgreSQL-only feed for Planet PostgreSQL: no SQL Server, Snowflake or MongoDB posts.
export const GET: APIRoute = () => {
  const feed = rssFeed({
    siteUrl: site.url,
    feedPath: '/rss/postgresql.xml',
    title: `${site.personName}: PostgreSQL guides`,
    link: `${site.url}/insights`,
    description: 'Lab-tested PostgreSQL performance, upgrade and pgvector guides by Kiran Sabne, with reproducible scripts.',
    author: site.personName,
    items: posts.filter((post) => post.postgresql)
  });
  return new Response(feed, { headers: { 'Content-Type': 'application/rss+xml; charset=utf-8' } });
};
