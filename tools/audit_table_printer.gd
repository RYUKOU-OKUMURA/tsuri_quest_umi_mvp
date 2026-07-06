extends RefCounted


static func print_table(title: String, columns: Array[String], rows: Array[Array]) -> void:
	var widths := _column_widths(columns, rows)
	print(title)
	print(_format_row(columns, widths))
	print(_separator(widths))
	for row in rows:
		print(_format_row(row, widths))


static func _column_widths(columns: Array[String], rows: Array[Array]) -> Array[int]:
	var widths: Array[int] = []
	for column in columns:
		widths.append(column.length())
	for row in rows:
		for index in range(mini(row.size(), widths.size())):
			widths[index] = maxi(widths[index], _value_text(row[index]).length())
	return widths


static func _format_row(row: Array, widths: Array[int]) -> String:
	var cells: Array[String] = []
	for index in range(widths.size()):
		var text := _value_text(row[index]) if index < row.size() else ""
		cells.append(text.rpad(widths[index]))
	return " | ".join(PackedStringArray(cells))


static func _separator(widths: Array[int]) -> String:
	var cells: Array[String] = []
	for width in widths:
		cells.append("-".repeat(width))
	return "-+-".join(PackedStringArray(cells))


static func _value_text(value: Variant) -> String:
	match typeof(value):
		TYPE_FLOAT:
			return "%.3f" % float(value)
		_:
			return str(value)
