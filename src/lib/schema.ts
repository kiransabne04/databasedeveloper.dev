import { site } from '../config/site';

/** Service structured data for a capability page, linked to the site-wide ProfessionalService. */
export function serviceSchema(name: string, path: string, description: string) {
  return {
    '@context': 'https://schema.org',
    '@type': 'Service',
    name,
    serviceType: name,
    description,
    url: site.url + path,
    areaServed: 'Worldwide',
    provider: { '@id': site.url + '/#practice' }
  };
}
