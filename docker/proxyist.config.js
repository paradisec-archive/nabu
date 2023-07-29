import { S3 } from '@aws-sdk/client-s3';

const s3Config = {
  forcePathStyle: true,
  credentials: {
    accessKeyId: 'S3RVER',
    secretAccessKey: 'S3RVER',
  },
  endpoint: 'http://s3:9090',
  region: 'ap-southeast-2',
};

const s3 = new S3(s3Config);

export default {
  bucket: 'nabu',
  s3,
  transform: (identifier) => {
    if (identifier.includes('/')) {
      throw new Error('Identifer cannot contain "/"');
    }

    if (identifier.includes('-')) {
      const [, item] = identifier.split('-', 2);
      if (item === 'root') {
        throw new Error('Item cannot be named "root"');
      }

      return identifier.replace(/-/, '/');
    }

    return `${identifier}/root`;
  },
};
