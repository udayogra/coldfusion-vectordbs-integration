component implements="vectordbs.interfaces.IVectorDB" {
    variables.host = "";
    variables.collection = "";
    variables.apiKey = "";

    function init(required struct config, required string collectionName, struct metadata={}) {
        variables.host = config.host;
        variables.collection = collectionName;
        variables.apiKey = config.keyExists("apiKey") ? config.apiKey : "";
        // Create collection if needed
        if (!indexExists(collectionName) && structKeyExists(metadata, "createIfMissing") && metadata.createIfMissing) {
            var creationResult = createBucket(collectionName, metadata.dimension, metadata.metric ?: "Cosine", metadata);
            if (structKeyExists(creationResult, "error")) {
                throw(message="Failed to create collection: " & creationResult.error & " (status: " & (creationResult.status ?: "") & ")");
            }
        }
        return this;
    }

    public boolean function indexExists(required string name) {
        var response = listBuckets();
        if (!structKeyExists(response, "result") || !structKeyExists(response.result, "collections")) return false;
        for (var c in response.result.collections) {
            if (structKeyExists(c, "name") && c.name == name) return true;
        }
        return false;
    }

    public any function createFieldIndex(required string fieldName, string fieldSchema="keyword") {
        var url = variables.host & "/collections/" & variables.collection & "/index";
        var payload = { "field_name": fieldName, "field_schema": fieldSchema };
        var headers = { "Content-Type": "application/json" };
        if (len(variables.apiKey)) headers["api-key"] = variables.apiKey;
        return new vectordbs.utils.HttpUtil().sendRequest(url, "put", headers, payload);
    }

    function insert(required any vector, struct metadata={}) {
        var url = variables.host & "/collections/" & variables.collection & "/points";
        var payload = {
            "points": [
                {
                    "id": metadata.keyExists("id") ? metadata.id : createUUID(),
                    "vector": vector,
                    "payload": metadata
                }
            ]
        };
        var headers = {"Content-Type": "application/json"};
        if (len(variables.apiKey)) headers["api-key"] = variables.apiKey;
        try {
            return new vectordbs.utils.HttpUtil().sendRequest(url, "put", headers, payload);
        } catch (any e) {
            return {"error": e.message};
        }
    }

    function listBuckets() {
        var url = variables.host & "/collections";
        var headers = {"Content-Type": "application/json"};
        if (len(variables.apiKey)) headers["api-key"] = variables.apiKey;
        try {
            return new vectordbs.utils.HttpUtil().sendRequest(url, "get", headers, structNew());
        } catch (any e) {
            return {"error": e.message};
        }
    }

    function delete(required any id, struct metadata={}) {
        if (!isStruct(metadata)) {
            metadata = {};
        }
        var url = variables.host & "/collections/" & variables.collection & "/points/delete";
        var payload = {"points": [id]};
        if (structKeyExists(metadata, "namespace")) {
            // Ensure namespace is indexed before filtering
            createFieldIndex("namespace");
            payload = {
                "filter": {
                    "must": [
                        { "key": "namespace", "match": { "value": metadata.namespace } }
                    ]
                }
            };
        }
        var headers = {"Content-Type": "application/json"};
        if (len(variables.apiKey)) headers["api-key"] = variables.apiKey;
        try {
            return new vectordbs.utils.HttpUtil().sendRequest(url, "post", headers, payload);
        } catch (any e) {
            return {"error": e.message};
        }
    }

    function search(required any queryVector, struct metadata={}) {
        if (!isStruct(metadata)) {
            metadata = {};
        }
        var url = variables.host & "/collections/" & variables.collection & "/points/search";
        var payload = {
            "vector": queryVector,
            "limit": metadata.keyExists("topK") ? metadata.topK : 5,
            "with_payload": metadata.keyExists("includeMetadata") ? metadata.includeMetadata : true
        };
        if (structKeyExists(metadata, "namespace")) {
            // Ensure namespace is indexed before filtering
            createFieldIndex("namespace");
            payload["filter"] = {
                "must": [
                    { "key": "namespace", "match": { "value": metadata.namespace } }
                ]
            };
        }
        writeOutput("Payload: " & serializeJSON(payload) & "<br>");
        var headers = {"Content-Type": "application/json"};
        if (len(variables.apiKey)) 
          headers["api-key"] = variables.apiKey;
        try {
            return new vectordbs.utils.HttpUtil().sendRequest(url, "post", headers, payload);
        } catch (any e) {
            return {"error": e.message};
        }
    }

    public any function createBucket(required any name, required any dimension, required string metric, struct metadata={}) {
        // Optionally override collection name
        if (isSimpleValue(name) && len(name)) variables.collection = name;
        return createCollection(name, dimension, metric, metadata);
    }

    public any function createCollection(required string name, required numeric size, string metric="Cosine", struct metadata={}) {
        var url = variables.host & "/collections/" & variables.collection;
        var payload = {
            "vectors": {
                "size": size,
                "distance": metric
            }
        };
        var headers = {"Content-Type": "application/json"};
        if (len(variables.apiKey)) headers["api-key"] = variables.apiKey;
        try {
            return new vectordbs.utils.HttpUtil().sendRequest(url, "put", headers, payload);
        } catch (any e) {
            return {"error": e.message};
        }
    }
} 