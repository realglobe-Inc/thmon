#!/bin/sh

#echo "DATAをバックアップしています" >&2
#./backup_data.sh

echo "DATAを削除します" >&2
rm -rf DATA

echo "リモートのDATAを転送しています" >&2
(ssh cm01.local 'cd /var/local/thmon && pax -w DATA | compress') |
  uncompress |
  pv |
  pax -r
