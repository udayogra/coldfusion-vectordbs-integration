component {
    public any function sendRequest(required string url, required string method, struct headers = {}, struct body = {}) {
        cfhttp(
            url = url,
            method = lcase(method),
            charset = "utf-8",
            result = "local.httpResponse",
            resolveurl = false
        ) {
            for (local.headerName in structKeyArray(headers)) {
                cfhttpparam(type = "header", name = local.headerName, value = headers[local.headerName]);
            }
            if (!structIsEmpty(body) && lcase(method) neq "get") {
                cfhttpparam(type = "body", value = serializeJSON(body));
            }
        }
        var statusCode = local.httpResponse.StatusCode ?: "";
        
        if (left(statusCode, 1) == "2") {
            if (len(trim(local.httpResponse.FileContent))) {
                return deserializeJSON(local.httpResponse.FileContent);
            } else {
                return {};
            }
        } else {
            var errorMsg = "";
            try {
                var errorStruct = deserializeJSON(local.httpResponse.FileContent);
                if (structKeyExists(errorStruct, "error") && structKeyExists(errorStruct.error, "message")) {
                    errorMsg = errorStruct.error.message;
                } else {
                    errorMsg = local.httpResponse.FileContent;
                }
            } catch (any parseErr) {
                errorMsg = local.httpResponse.FileContent;
            }
            return { "error": errorMsg, "status": statusCode };
        }
    }
} 