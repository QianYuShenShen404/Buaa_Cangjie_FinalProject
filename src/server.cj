package finalProject

import net.http.*
import std.collection.ArrayList
//新建server
let server = ServerBuilder().addr("127.0.0.1").port(8080).build()

func serverStart() {
    //注册处理函数
    server.distributor.register("/process", {httpContext =>
        var result = spawn {
            var form = httpContext.request.form
            var tool = form.get("tool").getOrThrow()
            var code = form.get("code").getOrThrow()
            //根据tool选项选择调用函数
            match (tool) {
                case "generateCodeSignature" =>
                    return CJCodeTool.generateCodeSignature(code)
                case "refactorVariable" =>
                    var path = form.get("path").getOrThrow()
                    var oldName = form.get("oldName").getOrThrow()
                    var newName = form.get("newName").getOrThrow()
                    return CJCodeTool.refactorVariable(code, path, oldName, newName)
                case "generateDocument" =>
                    var path = form.get("path").getOrThrow()
                    return CJCodeTool.generateDocument(code, path)
                case "foldConstant" =>
                    return CJCodeTool.foldConstant(code)
                case _ => return ""
            }
        }
        //构建响应
        httpContext.responseBuilder
        .header("Access-Control-Allow-Origin", "*")  // 允许所有来源访问
        .header("Access-Control-Allow-Methods", "POST, GET, OPTIONS")
        .header("Access-Control-Allow-Headers", "Content-Type")
        .body(result.get())
    })
    //启动服务器
    server.serve()
}

