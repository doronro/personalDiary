// Temporary file to exercise the Attest PR gate - do not merge.
const crypto = require('crypto');

function hashEntryId(s) {
  return crypto.createHash('md5').update(s).digest('hex');
}

module.exports = { hashEntryId };
