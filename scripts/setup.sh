#!/bin/bash

# Waiting for db to be up
echo "Waiting for startup.."
for db in "$PRIMARY_NODE" "$SECOUNDARY_NODE1" "$SECOUNDARY_NODE2"; do 
	echo "waiting for $db ..."
	until nc -z -w 2 "$db" 27017; do
		echo "$db" Ready
	done 
done

# Check if replicaset initialized
rs=$(mongo --host="$PRIMARY_NODE" --port=27017 -u "$MONGO_INITDB_ROOT_USERNAME" --password="$MONGO_INITDB_ROOT_PASSWORD" --eval "rs.status()" | grep ok | cut -d ":" -f 2 | cut -d "," -f 1)
if [ "$rs" -eq "1" ]; then
	echo "Replicaset Already initialized"
	exit 0
fi

# intializing Replication
mongo --host="$PRIMARY_NODE" --port=27017 -u "$MONGO_INITDB_ROOT_USERNAME" --password="$MONGO_INITDB_ROOT_PASSWORD" <<EOF
var cfg = {
      _id : 'rs',
      members: [
         { _id : 0, host : "${PRIMARY_NODE}:27017" },
         { _id : 1, host : "${SECOUNDARY_NODE1}:27017" },
         { _id : 2, host : "${SECOUNDARY_NODE2}:27017", arbiterOnly: true }
      ]
   }
   )
rs.initiate(cfg, { force: true });
rs.status();   
EOF
