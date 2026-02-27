class_name RouterTest extends SecureHttpRouter

signal other_signal
var serv : ServerTest = null


func _handle_post(_request: SecureHttpRequest, response: SecureHttpResponse) -> void:
	print("Received post")
	await other_signal
	var msg := "Heeey from async post"
	print(msg)
	response.send(200, msg, "text/plain")

func _handle_get(_request: SecureHttpRequest, response: SecureHttpResponse) -> void:
	print("Received get")
	other_signal.emit()
	response.send(200, "Hey from synchronous get", "text/plain")
