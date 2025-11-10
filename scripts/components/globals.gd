class_name Globals

static var GIZMO_ID: RID = rid_from_int64(0)
static var gizmo_handle_info: GizmoUtils.GizmoPartInfo = null
static var gizmo_entities_by_renderable_rid: Dictionary

static func any() -> RID:
	return rid_from_int64(FlecsScene.Constants.Any)
