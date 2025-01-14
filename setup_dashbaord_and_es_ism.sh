curl -X PUT "$ES_ENDPOINT/_opendistro/_ism/policies/log-policy" --insecure -u "$ES_USER:$ES_PASSWORD" -H 'Content-Type: application/json' -d'
{
  "policy": {
    "description": "Demonstrate a hot-warm-cold-delete workflow.",
    "default_state": "hot",
    "schema_version": 1,
    "states": [{
        "name": "hot",
        "actions": [
          {
            "rollover": {
              "min_index_age": "1d",
              "min_size": "20gb"
            }
          }
        ],
        "transitions": [{
          "state_name": "warm"
        }]
      },
      {
        "name": "warm",
        "actions": [{
          "replica_count": {
            "number_of_replicas": 0
          }
        },
        {
           "index_priority": {
           "priority": 50
           }
        },
        {
          "force_merge": {
            "max_num_segments": 1
          }
        }],
        "transitions": [{
          "state_name": "cold",
          "conditions": {
            "min_index_age": "2d"
          }
        }]
      },
      {
        "name": "cold",
        "actions": [
        {
          "read_only": {}
        }],
        "transitions": [{
          "state_name": "delete",
          "conditions": {
             "min_index_age": "7d"
          }
        }]
      },
      {
        "name": "delete",
        "actions": [
        {
          "delete": {}
        }]
      }
    ],
    "ism_template": {
      "index_patterns": ["logs*"],
      "priority": 100
    }
  }
}
'

curl -X PUT "$ES_ENDPOINT/_index_template/ism_rollover" --insecure -u "$ES_USER:$ES_PASSWORD" -H 'Content-Type: application/json' -d'
{
  "index_patterns": ["logs*"],
  "template": {
    "settings": {
      "number_of_shards": 2,
      "number_of_replicas": 1,
      "opendistro.index_state_management.policy_id": "log-policy",
      "opendistro.index_state_management.rollover_alias": "logs"
    }
  }
}'

curl -X PUT "$ES_ENDPOINT/logs-000001" --insecure -u "$ES_USER:$ES_PASSWORD" -H 'Content-Type: application/json' -d'
{
  "aliases": {
    "logs": {
      "is_write_index": true
    }
  }
}'

curl -X GET "$ES_ENDPOINT/_opendistro/_ism/explain/logs-000001" --insecure -u "$ES_USER:$ES_PASSWORD"

curl -XPOST "$KB_ENDPOINT/api/saved_objects/_import?overwrite=true" \
  -H "kbn-xsrf: true" -H "securitytenant: global" \
  --form file=@dashboard.ndjson \
  -u "$ES_USER:$ES_PASSWORD"
