import { site } from '../config/site';

export type Faq = { q: string; a: string };
export type PriceOffer = { name: string; price: number; description?: string };

const provider = {
  '@type': 'ProfessionalService',
  '@id': site.url + '/#practice',
  name: site.brand,
  founder: { '@type': 'Person', '@id': site.url + '/#kiran', name: site.personName }
};

/** Service structured data for a capability page, linked to the site-wide ProfessionalService. */
export function serviceSchema(name: string, path: string, description: string, offers?: PriceOffer[]) {
  return {
    '@context': 'https://schema.org',
    '@type': 'Service',
    name,
    serviceType: name,
    description,
    url: site.url + path,
    areaServed: 'Worldwide',
    provider,
    ...(offers?.length ? {
      offers: offers.map((o) => ({
        '@type': 'Offer',
        name: o.name,
        price: o.price.toFixed(2),
        priceCurrency: 'USD',
        ...(o.description ? { description: o.description } : {}),
        url: site.url + path,
        seller: { '@id': site.url + '/#practice' }
      }))
    } : {})
  };
}

export function breadcrumbSchema(name: string, path: string) {
  return {
    '@context': 'https://schema.org',
    '@type': 'BreadcrumbList',
    itemListElement: [
      { '@type': 'ListItem', position: 1, name: 'Home', item: site.url + '/' },
      { '@type': 'ListItem', position: 2, name, item: site.url + path }
    ]
  };
}

export function faqSchema(faq: Faq[]) {
  return {
    '@context': 'https://schema.org',
    '@type': 'FAQPage',
    mainEntity: faq.map((item) => ({ '@type': 'Question', name: item.q, acceptedAnswer: { '@type': 'Answer', text: item.a } }))
  };
}

/** Service + BreadcrumbList + FAQPage for one service page. */
export function servicePageSchema(opts: { name: string; path: string; description: string; breadcrumb: string; faq: Faq[]; offers?: PriceOffer[] }) {
  return [serviceSchema(opts.name, opts.path, opts.description, opts.offers), breadcrumbSchema(opts.breadcrumb, opts.path), faqSchema(opts.faq)];
}

export const investigationOffers: PriceOffer[] = [
  { name: 'Founding price, first 3 clients', price: 450, description: 'Fixed price for one production PostgreSQL database. Paid upfront.' },
  { name: 'Standard price', price: 750, description: 'Fixed price after the first 3 clients.' }
];
export const upgradeOffers: PriceOffer[] = [
  { name: 'Founding price', price: 600, description: 'Fixed price for one cluster and its proposed target version.' },
  { name: 'Standard price', price: 900, description: 'Fixed price after the founding period.' }
];
export const snapshotOffers: PriceOffer[] = [
  { name: 'Free snapshot review', price: 0, description: `Up to ${site.snapshotMonthlyCap} accepted snapshots a month.` }
];
