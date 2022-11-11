[
    {
      "Classification": "presto-connector-hive",
      "Properties": {
         "hive.metastore.uri": "thrift://${hive_host}:${hive_port}"
      }
    },
    {
      "Classification": "presto-config",
      "Properties": {
         "query.max-history": "200",
         "enable-dynamic-filtering": "TRUE",
         "experimental.query-limit-spill-enabled": "TRUE",
         "join-distribution-type": "AUTOMATIC",
         "optimizer.dictionary-aggregation": "TRUE",
         "optimizer.join-reordering-strategy": "AUTOMATIC",
         "experimental.spill-compression-enabled": "TRUE"
      }
    }
]
