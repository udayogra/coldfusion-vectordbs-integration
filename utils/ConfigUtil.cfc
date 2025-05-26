component {
    static struct function readConfig(required string path) {
        var fileContent = fileRead(path);
        return deserializeJSON(fileContent);
    }
} 