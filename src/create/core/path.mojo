from std.sys import argv


def script_dir() -> String:
    """Returns the directory containing the running script."""
    var path = argv()[0]
    var bytes = path.as_bytes()
    var last_slash = -1
    for i in range(len(bytes)):
        if bytes[i] == 47:  # '/'
            last_slash = i
    if last_slash < 0:
        return "."
    var result = String()
    for i in range(last_slash):
        result += String(chr(Int(bytes[i])))
    return result
