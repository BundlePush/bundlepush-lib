// TODO implement
export async function fetchOrganizationFromKey(key) {
  if (key.match(/valid/)) {
    return {
      organizationName: 'Cernov Apps',
    };
  }
  return null;
}
