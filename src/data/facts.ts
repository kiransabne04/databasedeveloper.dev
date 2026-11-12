export const pg14Facts = {
  verifiedOn: '2026-11-11',
  communityEol: '12 November 2026',
  // RDS for PostgreSQL and Aurora PostgreSQL publish the same PG14 major-version dates.
  rdsStandardSupportEnd: '28 February 2027',
  rdsExtendedSupportYear1Start: '1 March 2027',
  rdsExtendedSupportYear3Start: '1 March 2029',
  rdsExtendedSupportEnd: '28 February 2030',
  azureStandardSupportEnd: '31 January 2027',
  azureExtendedSupportStart: '1 February 2027',
  azureExtendedSupportEnd: '11 November 2029',
  latestMinorBeforeEol: '14.24',
  // Some PG14 minor versions lose standard support before the major version does.
  rdsEarlyMinorEnds: '14.18 and 14.19: 31 October 2026',
  auroraEarlyMinorEnds: '14.17: 30 November 2026; 14.18: 31 December 2026',
  postgresqlSource: 'https://www.postgresql.org/support/versioning/',
  awsSource: 'https://docs.aws.amazon.com/AmazonRDS/latest/PostgreSQLReleaseNotes/postgresql-release-calendar.html',
  auroraSource: 'https://docs.aws.amazon.com/AmazonRDS/latest/AuroraPostgreSQLReleaseNotes/aurorapostgresql-release-calendar.html',
  azureSource: 'https://learn.microsoft.com/en-us/azure/postgresql/configure-maintain/extended-support'
} as const;
