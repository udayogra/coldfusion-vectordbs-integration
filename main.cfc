component {
    function generateVector(required numeric size) {
        var vec = [];
        for (var i=1; i<=size; i++) {
            arrayAppend(vec, randRange(0, 1000)/1000); // random float between 0 and 1
        }
        return vec;
    }

    function run2() {
        var collectionName = "ogrrtya5";
        try {
            var configPath = "/Users/uogra/Downloads/cf-main/cfusion/wwwroot/vectordbs/vectordbs.json";
            var client = new factory.VectorDBFactory().getClient(configPath,collectionName,{"createIfMissing":false,"dimension":153,"metric":"dotproduct","spec":{"serverless":{"cloud":"aws","region":"us-east-1"}}});
            var vector = generateVector(1536);
            //var creation = client.createBucket(collectionName, 1536, "Dot", {"spec": {"serverless": {"cloud": "aws", "region": "us-east-1"}}});
           // writeOutput("List Buckets: " & serializeJSON(client.listBuckets()) & "<br>");
        
        //    writeOutput("Create Index: " & serializeJSON(creation) & "<br>");
            writeOutput("Insert: " & serializeJSON(client.insert(vector, {id="f47ac10b-58cc-4372-a567-0e02b2c3d479", namespace="ns1",text="This is dummy text"})) & "<br>");
          writeOutput("Search: " & serializeJSON(client.search(vector, {id="f47ac10b-58cc-4372-a567-0e02b2c3d479", namespace="ns1"})) & "<br>");  
           writeOutput("Delete: " & serializeJSON(client.delete("f47ac10b-58cc-4372-a567-0e02b2c3d479", {namespace="ns1"})) & "<br>");
           
        } catch (any e) {
            writeOutput("Error: " & e);
        }
    }

     function run() {
        var collectionName = "bhaiEKDUMnayahai";
        try {
            //this fille will contain API keys and host information
            var configPath = "/Users/uogra/Downloads/cf-main/cfusion/wwwroot/vectordbs/vectordbs.json";

            //depending upon the dptype set in config file, this factory will return the client object.
            //it will also create collection(in qdrnt)/bucket(in pinecone) if it doesn't exist if createIfMissing is true. Else it will throw an error.
            var client = new factory.VectorDBFactory().getClient(configPath,collectionName,{"createIfMissing":true,"dimension":1536,"metric":"Dot"});
            //for pinecone we need to pass spec as well.
            //var client = new factory.VectorDBFactory().getClient(configPath,collectionName,{"createIfMissing":false,"dimension":1536,"metric":"dotproduct","spec":{"serverless":{"cloud":"aws","region":"us-east-1"}}});
          
            var vector = generateVector(1536);
           //you can list buckets : collection/index
            writeOutput("List Buckets: " & serializeJSON(client.listBuckets()) & "<br>");
        
         //insert vector with metadata
           writeOutput("Insert: " & serializeJSON(client.insert(vector, {id="f47ac10b-58cc-4372-a567-0e02b2c3d469", text="This is dummy text", namespace="ns1"})) & "<br>");
          
          //search vector with metadata
          writeOutput("Search: " & serializeJSON(client.search(vector, {id="f47ac10b-58cc-4372-a567-0e02b2c3d469", namespace="ns1"})) & "<br>");  
           
           //delete vector 
           writeOutput("Delete: " & serializeJSON(client.delete("f47ac10b-58cc-4372-a567-0e02b2c3d469", {namespace="ns1"})) & "<br>");
           
        } catch (any e) {
            writeOutput("Error: " & e);
        }
    }
} 