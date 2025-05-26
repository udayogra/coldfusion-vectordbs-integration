# VectorDB ColdFusion Library

A unified ColdFusion interface for working with vector databases.  
**Currently supports: [Pinecone](https://www.pinecone.io/) and [Qdrant](https://qdrant.tech/)**.

---

## Features

- Abstracts away differences between Pinecone and Qdrant.
- Create, list, search, and delete vector collections (called "buckets" in code).
- Automatically creates a collection/index if it does not exist (optional).
- Simple, consistent API for both providers.

---

## Terminology

- **Bucket**: Generic term used in this library for a collection of vectors.
  - In **Pinecone**, a bucket is called an **index**.
  - In **Qdrant**, a bucket is called a **collection**.

---

## Configuration

All configuration is done via a JSON file (e.g., `vectordbs.json`).  
Example:

```json
{
  "dbType": "qdrant",
  "pinecone": {
    "apiKey": "YOUR_PINECONE_API_KEY"
  },
  "qdrant": {
    "apiKey": "YOUR_QDRANT_API_KEY",
    "host": "YOUR_QDRANT_HOST_URL"
  }
}
```

- Set `"dbType"` to `"pinecone"` or `"qdrant"` to choose the provider.
- Fill in the relevant API keys and host URLs.

---

## Quick Start Example

```coldfusion
// Path to your config file
var configPath = "/path/to/vectordbs.json";
var collectionName = "my_collection";

// Create a client (will create the bucket if it doesn't exist)
var client = new factory.VectorDBFactory().getClient(
    configPath,
    collectionName,
    {
        "createIfMissing": true,
        "dimension": 1536,
        "metric": "dotproduct", // or "cosine", "euclidean", etc.
        // For Pinecone only:
        "spec": {"serverless": {"cloud": "aws", "region": "us-east-1"}}
    }
);

// Generate a random vector
var vector = [];
for (var i=1; i<=1536; i++) arrayAppend(vector, randRange(0, 1000)/1000);

// Insert a vector
client.insert(vector, {id="unique-id", text="Example text", namespace="ns1"});

// Search for similar vectors
client.search(vector, {topK=5, namespace="ns1"});

// Delete a vector
client.delete("unique-id", {namespace="ns1"});

// List all buckets (collections/indexes)
client.listBuckets();
```

---

## API Reference

### `getClient(configPath, bucket, metadata={})`

Creates and returns a client for the specified provider and bucket.  
If the bucket (index/collection) does not exist and `createIfMissing` is true, it will be created.

- **configPath** (string): Path to your JSON config file.
- **bucket** (string): Name of the index (Pinecone) or collection (Qdrant).
- **metadata** (struct, optional):
  - `createIfMissing` (boolean): Create the bucket if it doesn't exist.
  - `dimension` (int): Vector dimension (required for creation).
  - `metric` (string): Similarity metric (called `metric` in Pinecone, `distance` in Qdrant; e.g., `"cosine"`, `"dotproduct"`, `"euclidean"`).
  - `namespace` (string, optional): Logical grouping within the bucket.
  - `spec` (struct, Pinecone only): Index specification (e.g., serverless config).

---

### `listBuckets()`

Lists all available buckets (indexes/collections) for the provider.

---

### `insert(vector, metadata={})`

Inserts a vector with optional metadata.

- **vector** (array): The vector to insert.
- **metadata** (struct, optional):
  - `id` (string): Unique ID for the vector (auto-generated if not provided).
  - `namespace` (string, optional): Logical grouping.
  - Any other metadata fields.

---

### `search(queryVector, metadata={})`

Searches for vectors similar to the given query vector.

- **queryVector** (array): The query vector.
- **metadata** (struct, optional):
  - `topK` (int): Number of results to return (default: 10 for Pinecone, 5 for Qdrant).
  - `namespace` (string, optional): Logical grouping.
  - `includeMetadata` (boolean, optional): Whether to include metadata in results.

---

### `delete(id, metadata={})`

Deletes a vector by ID (or, in some cases, deletes all vectors in a namespace).

- **id** (string): The vector ID to delete.
- **metadata** (struct, optional):
  - `namespace` (string, optional): Logical grouping.

---

## Parameter Explanations

| Parameter   | Required | Provider   | Description                                                                 |
|-------------|----------|------------|-----------------------------------------------------------------------------|
| spec        | Only for Pinecone | Pinecone   | Index specification (e.g., serverless config, dimension, metric)            |
| dimension   | Yes (on creation) | Both       | Number of dimensions for vectors                                            |
| metric/distance | Yes (on creation) | Both       | Similarity metric: called `metric` in Pinecone, `distance` in Qdrant. E.g., `"cosine"`, `"dotproduct"`, `"euclidean"`, etc. |
| namespace   | Optional | Both       | Logical grouping within a bucket                                            |
| topK        | Optional | Both       | Number of results to return in search                                       |
| includeMetadata | Optional | Both   | Whether to include metadata in search results                               |

- **spec**: Only required for Pinecone. Example: `{ "serverless": { "cloud": "aws", "region": "us-east-1" } }`
- **metric** (Pinecone) / **distance** (Qdrant): Similarity function for vector search. In code, use `metric` for both; it is mapped to the correct field for each provider.
- **namespace**: Used for logical separation of data (multi-tenancy, etc.).

### metric (Pinecone) / distance (Qdrant)

Specifies the similarity function for vector search.  
In code, always use the `metric` key; it is mapped to the correct field for each provider.

| Provider   | Parameter Name | Possible Values                                      |
|------------|----------------|-----------------------------------------------------|
| Pinecone   | metric         | `"cosine"`, `"euclidean"`, `"dotproduct"`           |
| Qdrant     | distance       | `"Cosine"`, `"Euclidean"`, `"Dot"`, `"Manhattan"`, `"Jaccard"`, `"Hamming"` |

> **Note:** Qdrant is case-sensitive for distance values.

---

### spec (Pinecone only)

Advanced index configuration for Pinecone.  
Example:

```json
"spec": {
  "serverless": {
    "cloud": "aws",
    "region": "us-east-1"
  }
}
```

- **serverless.cloud**: Cloud provider (`"aws"`, `"gcp"`, `"azure"`)
- **serverless.region**: Cloud region (e.g., `"us-east-1"`)

You may include other Pinecone index configuration options as needed.  
See [Pinecone create_index docs](https://docs.pinecone.io/reference/create_index) for more options.

---

## Notes

- **Buckets**: "Bucket" means "index" in Pinecone and "collection" in Qdrant.
- **API Keys**: Keep your API keys secure. Do not commit them to version control.
- **Error Handling**: All methods return a struct. If an error occurs, the struct will contain an `"error"` key.

---

## Example: Full Workflow

```coldfusion
var configPath = "/path/to/vectordbs.json";
var collectionName = "demo_collection";

// Create client (Qdrant or Pinecone, based on config)
var client = new factory.VectorDBFactory().getClient(
    configPath,
    collectionName,
    {
        "createIfMissing": true,
        "dimension": 1536,
        "metric": "cosine",
        // For Pinecone only:
        //"spec": {"serverless": {"cloud": "aws", "region": "us-east-1"}}
    }
);

// Generate a random vector
var vector = [];
for (var i=1; i<=1536; i++) arrayAppend(vector, randRange(0, 1000)/1000);

// Insert
client.insert(vector, {id="vec1", text="Sample", namespace="ns1"});

// Search
var results = client.search(vector, {topK=3, namespace="ns1"});

// Delete
client.delete("vec1", {namespace="ns1"});

// List buckets
var buckets = client.listBuckets();
```

---

## License

MIT

---

Let me know if you want to add more details, usage patterns, or troubleshooting tips! 