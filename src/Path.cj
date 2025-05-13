package finalProject

const FUNC_IN_CLASS: Int64 = 0
const FUNC_OR_CLASS: Int64 = 1
const ERROR: Int64 = 2

class Path {
    private var _type : Int64
    private var func_name : String
    private var class_name : String

    public mut prop kind:  Int64 {
        get() {
            _type
        }

        set(value) {
            _type = value
        }
    }

    public mut prop funcName: String {
        get() {
            func_name
        }

        set(value) {
            func_name = value
        }
    }

    public mut prop className: String {
        get() {
            class_name
        }

        set(value) {
            class_name = value
        }
    }

    init(path: String) {
       if (path.contains(".")) {
            if (path.split(".").size > 2) {
                 _type = ERROR
            } else {
                 _type = FUNC_IN_CLASS
            }
            func_name = path.split(".")[1]
            class_name = path.split(".")[0]
       } else {
            _type = FUNC_OR_CLASS
            func_name = path
            class_name = path
       } 
    }
}