# PARADISEC OCFL

## Useful Docs
* https://ocfl.io/1.1/spec/
* https://ocfl.io/1.1/implementation-notes/
* https://ocfl.io/1.1/spec/validation-codes.html
* https://github.com/sul-dlss-labs/OCFL-Tools

## Implementation Notes

Our approach to things that we can decide on from the spec

* OCFL 1.1
* Directories: v1, v2, v3...
* Digest: SHA256  (Prefer over 512 as 256 can be autocomputed by S3)
* contentDirectory: DO we want to change this, content is probably fine
* user: is this extensible?ci an we add an id that maps to the DB id as email addresses can change
* Extensions
  * 0005 - Mutable head (MAYBE)
    * Does this solve our many versions issue
    * Auto commit them every 24 hours??
  * 0008 - Schema Registry
  * ??? - Peter mentioned something for our identiifer layout I can't see how to massage the others into what we want
