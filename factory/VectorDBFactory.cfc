component {
    function getClient(required string configPath, required string name, struct metadata={}) {
        var config = new vectordbs.utils.ConfigUtil().readConfig(configPath);
        if (config.dbType == "pinecone") {
            return new clients.PineconeClient(config.pinecone, name, metadata);
        } else if (config.dbType == "qdrant") {
            return new clients.QdrantClient(config.qdrant, name, metadata);
        } else {
            throw(message="Unsupported DB type: " & config.dbType);
        }
    }
} 