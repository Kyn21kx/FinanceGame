class_name ServerTest extends SecureHttpServer

signal something

var router := RouterTest.new()
var req : HTTPRequest = null
var timer : float = 0
var sent: bool = false
var emitted: bool = false
var client : CurlHttpClient = null
const URL := "https://localhost:8081/do_thing"

func _ready() -> void:
	self.router.serv = self
	self.set_certificate_data("res://localhost.crt", "res://localhost.key", "")
	self.register_router("/do_thing", router)
	self.debugPrintEnabled = true
	self.set_logger_callback(func _callback(req: SecureHttpRequest):
		print("Received with body: ", req.get_body())
	)
	self.start(8081)
	self.client = CurlHttpClient.create_curl_client(2)
	self.req = HTTPRequest.new()
	self.add_child(self.req)
	pass

func _process(delta: float) -> void:
	self.timer += delta
	var trunc = floori(self.timer)
	if trunc > 8 && trunc < 10 && !emitted:
		self.emitted = true
		something.emit()
