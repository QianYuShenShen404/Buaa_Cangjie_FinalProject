package finalProject
import std.ast.*
import std.collection.*
import std.convert.*

let doNothing = { => }

class CJCodeTool {
    static func generateCodeSignature(code: String) :  String { 
        return "";
    }

    static func refactorVariable(code: String, path: String, oldName: String, newName: String) :  String { 
        try {
            var codeTokens = cangjieLex(code)        
            var clue = Path(path)
            if (clue.kind == ERROR) {
                return "ILLEGAL INPUT"
            }
            var codeProgram = parseProgram(codeTokens)
            var codeDels = codeProgram.decls
            var flag = false
            var newDecls = ArrayList<Decl>()
            for (decl in codeDels) {
                if (decl is FuncDecl) {
                    var funcDecl = (decl as FuncDecl).getOrThrow()
                    let name = funcDecl.identifier.value
                    if ((clue.kind == FUNC_OR_CLASS) && name.compare(clue.funcName) == Ordering.EQ) {
                        newDecls.append(refactorFunc(funcDecl, oldName, newName))
                        flag = true
                        continue
                    }
                }
                if (decl is ClassDecl) {
                    var classDecl = (decl as ClassDecl).getOrThrow()
                    let name = classDecl.identifier.value
                    if (name.compare(clue.className) == Ordering.EQ) {
                        if (clue.kind == FUNC_IN_CLASS) {
                            for (decl in classDecl.body.decls) {
                                if (decl is FuncDecl) {
                                    let funcDecl = (decl as FuncDecl).getOrThrow()
                                    if (funcDecl.identifier.value.compare(clue.funcName) == Ordering.EQ) {
                                        newDecls.append(refactorClass(classDecl, oldName, newName, clue))
                                        flag = true
                                    }
                                }
                            }
                            continue
                        } else {
                            newDecls.append(refactorClass(classDecl, oldName, newName, clue))
                            flag = true
                            continue
                        }
                    }
                }
                newDecls.append(decl)
            }
            if (!flag) {
                return "ILLEGAL INPUT"
            }
            codeProgram.decls = newDecls
            return codeProgram.toTokens().toString()
        } catch (e: Exception) {
            return "ILLEGAL INPUT"
        }
    }

    static func generateDocument(code: String, path: String) :  String { 
        return ""
    }

    static func foldConstant(code: String) :  String {
        try {
            var codeTokens = cangjieLex(code)
            var codeProgram = parseProgram(codeTokens)
            var newDecls = ArrayList<Decl>()
            for (decl in codeProgram.decls) {
                newDecls.append(foldDecl(decl))
            }
            codeProgram.decls = newDecls
            return  codeProgram.toTokens().toString()
        } catch (e: Exception) {
            return "ILLEGAL INPUT"
        }
    }

    static func refactorFunc(funcDecl: FuncDecl, oldName: String, newName: String) { 
        var oldFuncTokens = funcDecl.toTokens()
        var newFuncTokens = Tokens()
        for (token in oldFuncTokens) {
            if (token.kind == TokenKind.IDENTIFIER && token.value == oldName) {
                newFuncTokens.append(Token(TokenKind.IDENTIFIER, newName))
            } else {
                newFuncTokens.append(token)
            }
        }
        return FuncDecl(newFuncTokens)
    }

    static func refactorClass(classDecl: ClassDecl, oldName: String, newName: String, path: Path) : ClassDecl { 
        if (path.kind == FUNC_IN_CLASS) {
            var oldClassBody = classDecl.body
            var newClassBody = ArrayList<Decl>()
            for (decl in oldClassBody.decls) {
                if (decl is FuncDecl) {
                    var funcDecl = (decl as FuncDecl).getOrThrow()
                    let name = funcDecl.identifier.value
                    if (name.compare(path.funcName) == Ordering.EQ) {
                        newClassBody.append(refactorFunc(funcDecl, oldName, newName))
                        continue
                    }
                }
                newClassBody.append(decl)
            }
            classDecl.body = Body(newClassBody)
            return classDecl
        }
        var oldClassTokens = classDecl.toTokens()
        var newClassTokens = Tokens()
        for (token in oldClassTokens) {
            if (token.kind == TokenKind.IDENTIFIER) {
                if (token.value.compare(oldName) == Ordering.EQ) {
                    newClassTokens.append(Token(TokenKind.IDENTIFIER, newName))
                    continue
                }
            }
            newClassTokens.append(token)
        }
        return ClassDecl(newClassTokens)
    }

    static func foldDecl(decl: Decl): Decl {
        if (decl is ClassDecl) {
            let classDecl = (decl as ClassDecl).getOrThrow()
            classDecl.body = foldBody(classDecl.body)
            return classDecl
        } else if (decl is FuncDecl) {
            let funcDecl = (decl as FuncDecl).getOrThrow()
            funcDecl.block = foldBlock(funcDecl.block)
            var funcParams = funcDecl.funcParams
            for (funcParam in funcParams) {
                try {
                    var expr = funcParam.expr
                    funcParam.expr = foldExpr(expr)
                } catch (e: Exception) {
                    continue
                }
            }
            return funcDecl
        } else if (decl is VarDecl) {
            let varDecl = (decl as VarDecl).getOrThrow()
            varDecl.expr = foldExpr(varDecl.expr)
            return varDecl
        } else {
            throw Exception()
        }
    }

    static func foldExpr(expr: Expr): Expr {
        if (expr is AssignExpr) {
            let assignExpr = (expr as AssignExpr).getOrThrow()
            assignExpr.leftExpr = foldExpr(assignExpr.leftExpr)
            assignExpr.rightExpr = foldExpr(assignExpr.rightExpr)
            return assignExpr
        } else if (expr is BinaryExpr) {
            let binaryExpr = (expr as BinaryExpr).getOrThrow()
            binaryExpr.leftExpr = foldExpr(binaryExpr.leftExpr)
            binaryExpr.rightExpr = foldExpr(binaryExpr.rightExpr)
            if (binaryExpr.leftExpr is LitConstExpr && binaryExpr.rightExpr is LitConstExpr) {
                var left = (binaryExpr.leftExpr as LitConstExpr).getOrThrow().literal
                var right = (binaryExpr.rightExpr as LitConstExpr).getOrThrow().literal
                if ((left.kind.toString().compare(TokenKind.INTEGER_LITERAL.toString()) == EQ && right.kind.toString().compare(TokenKind.INTEGER_LITERAL.toString()) == EQ) || (left.kind.toString().compare(TokenKind.INT64.toString()) == EQ && right.kind.toString().compare(TokenKind.INT64.toString()) == EQ)) {
                    match (binaryExpr.op.kind) {
                        case TokenKind.ADD => 
                        // 合并加法表达式
                            return LitConstExpr((Int64.parse(left.value.toString()) + Int64.parse(right.value.toString())).toTokens())
                        case TokenKind.SUB => 
                            return LitConstExpr((Int64.parse(left.value.toString()) - Int64.parse(right.value.toString())).toTokens())
                        case TokenKind.MUL => 
                            return LitConstExpr((Int64.parse(left.value.toString()) * Int64.parse(right.value.toString())).toTokens())
                        case TokenKind.DIV => 
                            return LitConstExpr((Int64.parse(left.value.toString()) / Int64.parse(right.value.toString())).toTokens())
                        case TokenKind.MOD => 
                            return LitConstExpr((Int64.parse(left.value.toString()) % Int64.parse(right.value.toString())).toTokens())
                        case _ =>
                            throw Exception()
                            // 不支持的操作符，直接失败
                    }
                } else if ((left.kind == TokenKind.FLOAT_LITERAL && right.kind == TokenKind.FLOAT_LITERAL) || (left.kind == TokenKind.FLOAT64 && right.kind == TokenKind.FLOAT64)) { 
                    match (binaryExpr.op.kind) {
                        case TokenKind.ADD => 
                            return LitConstExpr((Float64.parse(left.value.toString()) + Float64.parse(right.value.toString())).toTokens())
                        case TokenKind.SUB =>
                            return LitConstExpr((Float64.parse(left.value.toString()) - Float64.parse(right.value.toString())).toTokens())
                        case TokenKind.MUL =>
                            return LitConstExpr((Float64.parse(left.value.toString()) * Float64.parse(right.value.toString())).toTokens())
                        case TokenKind.DIV => 
                            return LitConstExpr((Float64.parse(left.value.toString()) / Float64.parse(right.value.toString())).toTokens())
                        case _ => 
                            throw Exception()
                    }
                } else {
                    throw Exception()
                }
            }
            return binaryExpr
        } else if (expr is UnaryExpr) {
            let unaryExpr = (expr as UnaryExpr).getOrThrow()
            unaryExpr.expr = foldExpr(unaryExpr.expr)
            if (unaryExpr.expr is LitConstExpr) {
                if (unaryExpr.op.kind.toString().compare(TokenKind.SUB.toString()) == EQ) {
                    let litToken = (unaryExpr.expr as LitConstExpr).getOrThrow().literal
                    match (litToken.kind) {
                        case TokenKind.INT64 =>
                            return LitConstExpr((-Int64.parse(litToken.value.toString())).toString().toTokens())
                        case TokenKind.FLOAT64 =>
                            return LitConstExpr((-Float64.parse(litToken.value.toString())).toString().toTokens())
                        case _ =>
                            throw Exception()
                    }
                } else {
                    throw Exception()
                }
            } else {
                return unaryExpr
            }
        } else if (expr is ForInExpr) {
            let forInExpr = (expr as ForInExpr).getOrThrow()
            forInExpr.expr = foldExpr(forInExpr.expr)
            forInExpr.patternGuard = foldExpr(forInExpr.patternGuard)
            forInExpr.block = foldBlock(forInExpr.block)
            return forInExpr
        } else if (expr is IfExpr) {
            let ifExpr = (expr as IfExpr).getOrThrow()
            ifExpr.ifBlock = foldBlock(ifExpr.ifBlock)
            try {
                ifExpr.elseExpr = foldExpr(ifExpr.elseExpr)
            } catch (e: Exception) {
                doNothing
            }
        } else if (expr is LitConstExpr) {
            return expr
        } else if (expr is ReturnExpr) {
            let returnExpr = (expr as ReturnExpr).getOrThrow()
            returnExpr.expr = foldExpr(returnExpr.expr)
            return returnExpr
        } else if (expr is ParenExpr) {
            let parenExpr = (expr as ParenExpr).getOrThrow()
            parenExpr.parenthesizedExpr = foldExpr(parenExpr.parenthesizedExpr)
            return parenExpr
        } else if (expr is RangeExpr) {
            let rangeExpr = (expr as RangeExpr).getOrThrow()
            try {
                rangeExpr.start = foldExpr(rangeExpr.start)
            } catch (e: Exception) {
                doNothing
            }
            try {
                rangeExpr.end = foldExpr(rangeExpr.end)
            } catch (e: Exception) {
                doNothing
            }         
            return rangeExpr
        }
        return expr
    }

    static func foldNode(node: Node): Node {
        if (node is Expr) {
            return foldExpr((node as Expr).getOrThrow())
        } else if (node is Body) {
            return foldBody((node as Body).getOrThrow())
        } else if (node is Decl) {
            return foldDecl((node as Decl).getOrThrow())
        } else {
            return node
        }
    }

    static func foldBody(body: Body): Body {
        var newDecls = ArrayList<Decl>()
        for (decl in body.decls) {
            newDecls.append(foldDecl(decl))
        }
        body.decls = newDecls
        return body
    }

    static func foldBlock(block: Block): Block {
        var newNodes = ArrayList<Node>()
        for (node in block.nodes) {
            newNodes.append(foldNode(node))
        }
        block.nodes = newNodes
        return block
    }
}