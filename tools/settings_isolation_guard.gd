extends RefCounted


static func raw_absolute_path_is_unambiguous(path: String) -> bool:
	if path.is_empty() or path != path.strip_edges() or not path.is_absolute_path() or path != path.simplify_path():
		return false
	for component in path.split("/", true):
		if component == "." or component == "..":
			return false
	return true
