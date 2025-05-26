component implements="vectordbs.interfaces.IVectorDB" {
    variables.apiKey = "";
    variables.indexName = "";
    variables.host = "";

    function init(required struct config, required string indexName, struct metadata={}) {
        variables.apiKey = config.apiKey;
        variables.indexName = indexName;
        // Create index if needed
        if (structKeyExists(metadata, "createIfMissing") && metadata.createIfMissing) {
            if (!indexExists(indexName)) {
                var creationResult = createBucket(indexName, metadata.dimension, metadata.metric ?: "cosine", metadata);
                if (structKeyExists(creationResult, "error")) {
                    throw(message="Failed to create index: " & creationResult.error & " (status: " & (creationResult.status ?: "") & ")");
                }
            }
        }
        // Find the host for the given index name
        var allIndexes = listBuckets();
        if (structKeyExists(allIndexes, "indexes")) {
            for (var idx in allIndexes.indexes) {
                if (structKeyExists(idx, "name") && idx.name == indexName) {
                    variables.host = "https://" & idx.host;
                    //break;
                }
            }
        }
        if (!len(variables.host)) {
            throw(message="Index '" & indexName & "' not found in Pinecone account.");
        }
        return this;
    }

    private string function getBaseUrl() {
        return variables.host;
    }

    private struct function getHeaders() {
        return {
            "Api-Key": variables.apiKey,
            "Content-Type": "application/json"
        };
    }

    function insert(required any vector, any metadata) {
        var url = getBaseUrl() & "/vectors/upsert";
        var payload = {
            "vectors": [
                {
                    "id": metadata.keyExists("id") ? metadata.id : createUUID(),
                    "values": vector,
                    "metadata": metadata
                }
            ],
            "namespace": metadata.keyExists("namespace") ? metadata.namespace : "default"
        };
        var headers = getHeaders();
        try {
            return new vectordbs.utils.HttpUtil().sendRequest(url, "post", headers, payload);
        } catch (any e) {
            return {"error": e.message};
        }
    }

    function delete(required any id, any metadata) {
        var url = getBaseUrl() & "/vectors/delete";
        var payload = {
            "ids": [id],
            "namespace": metadata.keyExists("namespace") ? metadata.namespace : "default"
        };
        var headers = getHeaders();
        try {
            return new vectordbs.utils.HttpUtil().sendRequest(url, "post", headers, payload);
        } catch (any e) {
            return {"error": e.message};
        }
    }

    function search(required any queryVector, any metadata) {
        var url = getBaseUrl() & "/query";
        var payload = {
            "vector": queryVector,
            "topK": metadata.keyExists("topK") ? metadata.topK : 10,
            "includeValues": true,
            "includeMetadata": metadata.keyExists("includeMetadata") ? metadata.includeMetadata : true,
            "namespace": metadata.keyExists("namespace") ? metadata.namespace : "default"
        };
        var headers = getHeaders();
        try {
            return new vectordbs.utils.HttpUtil().sendRequest(url, "post", headers, payload);
        } catch (any e) {
            return {"error": e.message};
        }
    }

    public boolean function indexExists(required string name) {
        var response = listBuckets(); // Should return the parsed struct as you showed
        if (!structKeyExists(response, "indexes")) return false;
        for (idx in response.indexes) {
            if (structKeyExists(idx, "name") && idx.name == name) {
                return true;
            }
        }
        return false;
    }

    public any function createIndex(required string name, required numeric dimension, string metric="cosine", struct metadata={}) {
        if (indexExists(name)) {
            return {"message": "Index already exists", "index": name};
        }
        var url = "https://api.pinecone.io/indexes";
        var payload = {
            "name": name,
            "dimension": dimension,
            "metric": metric
        };
        // Merge metadata.spec and any other top-level keys into payload
        if (structKeyExists(metadata, "spec")) {
            payload["spec"] = metadata.spec;
        }
        for (var k in metadata) {
            if (!structKeyExists(payload, k) && k != "spec") {
                payload[k] = metadata[k];
            }
        }
        var headers = getHeaders();
        return new vectordbs.utils.HttpUtil().sendRequest(url, "post", headers, payload);
    }

    public any function listBuckets() {
        var url = "https://api.pinecone.io/indexes";
        var headers = getHeaders();
        try {
            return new vectordbs.utils.HttpUtil().sendRequest(url, "get", headers, structNew());
        } catch (any e) {
            return {"error": e.message};
        }
    }

    public any function createBucket(required any name, required any dimension, required string metric, struct metadata={}) {
        return createIndex(name, dimension, metric, metadata);
    }
} 