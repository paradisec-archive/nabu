const bucketName = process.env.BUCKET_NAME;
if (!bucketName) {
  throw new Error('BUCKET_NAME environment variable must be set');
}

export default {
  bucket: bucketName,
  returnRedirects: true,
  transform: (identifier) => {
    if (identifier.includes('/')) {
      throw new Error('Identifer cannot contain "/"');
    }

    if (identifier.includes('-')) {
      const [, item] = identifier.split('-', 2);
      if (item === '__object__') {
        throw new Error('Item cannot be named "root"');
      }

      return identifier.replace(/-/, '/');
    }

    return `${identifier}/__object__`;
  },
};
