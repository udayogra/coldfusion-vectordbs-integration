 interface {
    any function init(required struct config, required string name, struct metadata={});
    any function insert(required any vector, any metadata);
    any function delete(required any id, any metadata);
    any function search(required any queryVector, any metadata);
    any function createBucket(required any name, required any dimension, required string metric, struct metadata={});
} 