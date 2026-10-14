<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:s="http://www.sitemaps.org/schemas/sitemap/0.9">
  <xsl:output method="html" encoding="UTF-8" indent="yes"/>
  <xsl:template match="/">
    <html lang="en">
      <head>
        <meta charset="UTF-8"/>
        <meta name="robots" content="noindex"/>
        <title>Sitemap — DatabaseDeveloper</title>
        <style>
          body { font-family: system-ui, -apple-system, sans-serif; background: #0b1110; color: #e6efe9; margin: 2rem; line-height: 1.5; }
          h1 { font-size: 1.4rem; margin: 0 0 .25rem; }
          p { color: #9fb2a9; margin: 0 0 1.5rem; }
          table { border-collapse: collapse; width: 100%; max-width: 960px; }
          td { padding: .45rem .6rem; border-bottom: 1px solid #1f2b28; font-size: .92rem; }
          a { color: #8ef0c1; text-decoration: none; }
          a:hover { text-decoration: underline; }
          .n { color: #6f8279; width: 3rem; }
        </style>
      </head>
      <body>
        <h1>DatabaseDeveloper sitemap</h1>
        <xsl:choose>
          <xsl:when test="s:sitemapindex">
            <p>This index lists <xsl:value-of select="count(s:sitemapindex/s:sitemap)"/> sitemap file(s). Search engines read this XML; the table is only for people.</p>
            <table>
              <xsl:for-each select="s:sitemapindex/s:sitemap">
                <tr><td class="n"><xsl:value-of select="position()"/></td><td><a href="{s:loc}"><xsl:value-of select="s:loc"/></a></td></tr>
              </xsl:for-each>
            </table>
          </xsl:when>
          <xsl:otherwise>
            <p><xsl:value-of select="count(s:urlset/s:url)"/> URLs. Search engines read this XML; the table is only for people.</p>
            <table>
              <xsl:for-each select="s:urlset/s:url">
                <tr><td class="n"><xsl:value-of select="position()"/></td><td><a href="{s:loc}"><xsl:value-of select="s:loc"/></a></td></tr>
              </xsl:for-each>
            </table>
          </xsl:otherwise>
        </xsl:choose>
      </body>
    </html>
  </xsl:template>
</xsl:stylesheet>
