class_name Relationships

static var MAGNETIZED_BY: RID

static var MANIPULATING: RID

static func child_of() -> RID:
	return rid_from_int64(FlecsScene.Constants.ChildOf)
